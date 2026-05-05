

import os
import numpy as np
import pandas as pd
from PIL import Image
from tensorflow.keras.applications import ResNet50
from tensorflow.keras.applications.resnet50 import preprocess_input
import tensorflow as tf

# ============================================================================
# Configuration
# ============================================================================
IMG_SIZE = (256, 256)
BATCH_SIZE = 32

# Path to training data (adjust for your environment)
# On Kaggle: /kaggle/input/chest-xray-pneumonia/chest_xray/train
# Locally: adjust as needed
TRAIN_DATA_PATH = "/kaggle/input/chest-xray-pneumonia/chest_xray/train"

# Output path for centroids CSV
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "weights")
OUTPUT_CSV = os.path.join(OUTPUT_DIR, "class_centroids.csv")

# Classes in the dataset
CLASSES = ["NORMAL", "PNEUMONIA"]


def load_resnet50_feature_extractor():
    """
    Load ResNet50 as a feature extractor.
    Uses ImageNet weights, excludes the top classification layer,
    and uses global average pooling to get a 2048-dim feature vector.
    """
    print("Loading ResNet50 feature extractor...")
    model = ResNet50(
        weights='imagenet',
        include_top=False,
        pooling='avg',
        input_shape=(IMG_SIZE[0], IMG_SIZE[1], 3)
    )
    model.trainable = False
    print(f"ResNet50 loaded. Output feature dimension: {model.output_shape[-1]}")
    return model


def load_and_preprocess_image(image_path):
    """Load an image, resize it, and apply ResNet50 preprocessing."""
    try:
        img = Image.open(image_path)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        img = img.resize(IMG_SIZE)
        img_array = np.array(img, dtype=np.float32)
        # Apply ResNet50-specific preprocessing (caffe-style)
        img_array = preprocess_input(img_array)
        return img_array
    except Exception as e:
        print(f"  Warning: Could not load {image_path}: {e}")
        return None


def extract_features_for_class(model, class_name, data_path):
    """
    Extract ResNet50 features for all images in a given class directory.
    Returns the feature matrix (N x 2048).
    """
    class_dir = os.path.join(data_path, class_name)
    if not os.path.isdir(class_dir):
        raise FileNotFoundError(f"Class directory not found: {class_dir}")

    image_files = [
        f for f in os.listdir(class_dir)
        if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.webp'))
    ]
    print(f"\n  Class '{class_name}': Found {len(image_files)} images")

    # Process in batches for efficiency
    all_features = []
    batch = []
    processed = 0

    for i, fname in enumerate(image_files):
        img_array = load_and_preprocess_image(os.path.join(class_dir, fname))
        if img_array is not None:
            batch.append(img_array)

        # When batch is full or last image, extract features
        if len(batch) == BATCH_SIZE or (i == len(image_files) - 1 and len(batch) > 0):
            batch_array = np.array(batch)
            features = model.predict(batch_array, verbose=0)
            all_features.append(features)
            processed += len(batch)
            print(f"    Processed {processed}/{len(image_files)} images...")
            batch = []

    if len(all_features) == 0:
        raise ValueError(f"No valid images found for class '{class_name}'")

    features_matrix = np.vstack(all_features)
    print(f"  Feature matrix shape: {features_matrix.shape}")
    return features_matrix


def compute_and_save_centroids(model, data_path, output_csv):
    """
    Compute class centroids and save to CSV.
    Each row: class_name, feature_0, feature_1, ..., feature_2047
    """
    print("\n" + "=" * 60)
    print("Computing class centroids from training data")
    print("=" * 60)

    centroids = {}
    for class_name in CLASSES:
        features = extract_features_for_class(model, class_name, data_path)
        # Compute centroid (mean feature vector)
        centroid = np.mean(features, axis=0)
        # Normalize the centroid for cosine similarity
        centroid_norm = centroid / np.linalg.norm(centroid)
        centroids[class_name] = centroid_norm
        print(f"  Centroid for '{class_name}': norm = {np.linalg.norm(centroid_norm):.4f}")

    # Save to CSV
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)

    feature_cols = [f"feature_{i}" for i in range(len(next(iter(centroids.values()))))]
    rows = []
    for class_name, centroid in centroids.items():
        row = {"class_name": class_name}
        for i, val in enumerate(centroid):
            row[f"feature_{i}"] = val
        rows.append(row)

    df = pd.DataFrame(rows)
    df.to_csv(output_csv, index=False)
    print(f"\nCentroids saved to: {output_csv}")
    print(f"CSV shape: {df.shape} (classes x [name + features])")

    return centroids


def verify_centroids(output_csv):
    """Load and verify the saved centroids."""
    print("\n" + "=" * 60)
    print("Verification")
    print("=" * 60)

    df = pd.read_csv(output_csv)
    print(f"Loaded CSV: {df.shape}")
    print(f"Classes: {df['class_name'].tolist()}")

    for _, row in df.iterrows():
        class_name = row['class_name']
        features = row.drop('class_name').values.astype(np.float64)
        norm = np.linalg.norm(features)
        print(f"  {class_name}: {len(features)} features, norm = {norm:.4f}")

    # Compute similarity between centroids
    if len(df) >= 2:
        c1 = df.iloc[0].drop('class_name').values.astype(np.float64)
        c2 = df.iloc[1].drop('class_name').values.astype(np.float64)
        similarity = np.dot(c1, c2) / (np.linalg.norm(c1) * np.linalg.norm(c2))
        print(f"\n  Cosine similarity between NORMAL and PNEUMONIA centroids: {similarity:.4f}")
        print(f"  (These are both X-ray images, so similarity should be relatively high)")

    print("\nVerification complete!")


if __name__ == "__main__":
    # Check if training data exists
    if not os.path.isdir(TRAIN_DATA_PATH):
        print(f"ERROR: Training data not found at: {TRAIN_DATA_PATH}")
        print("Please adjust TRAIN_DATA_PATH to point to your training data directory.")
        print("Expected structure:")
        print(f"  {TRAIN_DATA_PATH}/")
        print(f"    NORMAL/")
        print(f"    PNEUMONIA/")
        exit(1)

    # Load feature extractor
    feature_model = load_resnet50_feature_extractor()

    # Extract features and compute centroids
    centroids = compute_and_save_centroids(feature_model, TRAIN_DATA_PATH, OUTPUT_CSV)

    # Verify
    verify_centroids(OUTPUT_CSV)

    print("\n✅ Feature extraction complete!")
    print(f"   CSV file: {OUTPUT_CSV}")
    print("   Copy this file to your API server's weights/ directory.")

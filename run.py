import os
from app import create_app
app = create_app()

with app.app_context():
    from app.services.ml_service import ml_service
    weights_path = os.path.join(
        os.path.dirname(__file__),
        'weights',
        'pneumonia_detection_model.keras'
    )
    print("Loading ML model...")
    ml_service.load_model(weights_path)
    print(f"Model loaded: {ml_service.model_loaded}")

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'True').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)

# mini-gen/textgen-service/app.py
import os
from flask import Flask, request, jsonify
from groq import Groq
from dotenv import load_dotenv

# Load .env variables locally for development. Docker Compose handles this 
# via 'env_file' in production.
load_dotenv()

# Initialize the Flask web application.
app = Flask(__name__)

# Retrieve the secret key from the environment (either .env locally or Docker env_file).
GROQ_API_KEY = os.environ.get("GROQ_API_KEY")

# --- Groq Client Initialization ---
if not GROQ_API_KEY:
    # If the key is missing, log a warning. The app continues to run but API calls will fail.
    app.logger.warning("GROQ_API_KEY not set. Set it in the environment or in the root .env file.")

groq_client = None
try:
    # Attempt to create the Groq client object using the key.
    groq_client = Groq(api_key=GROQ_API_KEY)
except Exception as e:
    # If initialization fails (e.g., bad key format), log the error.
    app.logger.warning(f"Could not initialize Groq client: {e}")
    groq_client = None

# --- API Endpoint Definition ---
@app.route("/generate", methods=["POST"])
def generate():
    """API endpoint called by the frontend to trigger text generation."""
    
    # Safely try to get the JSON body from the request. Returns an empty dict if invalid.
    data = request.get_json(silent=True) or {}
    # Extract the 'prompt' field and clean whitespace.
    prompt = data.get("prompt", "").strip()
    
    # Validation: Check if the prompt is empty.
    if not prompt:
        return jsonify({"error": "Missing 'prompt' in JSON body"}), 400

    # Validation: Check if the Groq client is ready to make calls.
    if not GROQ_API_KEY or not groq_client:
        return jsonify({"error": "GROQ API key not set or Groq client unavailable on the server."}), 500

    # System instruction: This guides the AI model to be concise and follow the 20-word limit.
    system_instructions = (
        "You are a concise assistant. Produce an answer that is AT MOST 20 WORDS long. "
        "Do not include extraneous explanations, lists, or surrounding punctuation. "
        "If the user's prompt requires more than 20 words for full accuracy, produce a concise 20-word summary."
    )

    # Structure the message list for the Groq chat API call.
    messages = [
        {"role": "system", "content": system_instructions},
        {"role": "user", "content": prompt},
    ]

    # --- Groq API Call Logic ---
    try:
        # Send the request to Groq for text generation using the llama-3.1-8b-instant model.
        completion = groq_client.chat.completions.create(
            messages=messages,
            model="llama-3.1-8b-instant"
        )
        
        # Extract content from the response object.
        raw = ""
        try:
            # Standard way to access the generated text.
            raw = completion.choices[0].message.content
        except Exception:
            # Fallback for unexpected response structures.
            raw = getattr(completion, "content", "") or str(completion)

        # --- Post-Processing to Enforce Hard Limit ---
        # Split the raw text into a list of words.
        words = raw.strip().split()
        
        if len(words) > 20:
            # If the output exceeds 20 words, truncate it to the first 20 words.
            truncated = " ".join(words[:20])
            generated = truncated
        else:
            # Otherwise, use the output as is.
            generated = raw.strip()

        # Return the final generated text as JSON (HTTP 200 OK).
        return jsonify({"generated": generated}), 200

    except Exception as e:
        # Catch and report any network, rate limit, or client-side errors during the API call.
        app.logger.exception("Error calling Groq API")
        return jsonify({"error": f"Exception while calling Groq API: {str(e)}"}), 500

# --- Application Entry Point ---
if __name__ == "__main__":
    # The API server runs on internal port 5001, accessible only within the Docker network.
    app.run(host="0.0.0.0", port=5001)

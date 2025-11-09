# mini-gen/frontend-service/app.py
from flask import Flask, request, render_template_string, redirect, url_for
import os
import requests
from dotenv import load_dotenv

# Load environment variables (like TEXTGEN_HOST) from a .env file locally 
# only when running *outside* Docker for development convenience.
load_dotenv()

# Initialize the Flask web application instance.
app = Flask(__name__)

# Retrieves the TextGen host URL from the environment (set by docker-compose)
# or defaults to a local URL if running outside the container setup.
TEXTGEN_HOST = os.environ.get("TEXTGEN_HOST", "http://localhost:5001")

# --- HTML Template for the Web UI ---
HTML_PAGE = """
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>mini-gen — Frontend</title>
    <style>
      /* Basic CSS styling for a clean, centered layout */
      body { font-family: Arial, sans-serif; margin: 40px; max-width: 800px; }
      textarea { width: 100%; height: 120px; }
      .result { margin-top: 20px; padding: 12px; border: 1px solid #ddd; background: #f9f9f9; }
      button { padding: 8px 16px; font-size: 16px; }
      label { font-weight: bold; }
    </style>
  </head>
  <body>
    <h1>mini-gen — Frontend</h1>
    <form method="post" action="/">
      <label for="prompt">Enter your prompt:</label><br/>
      <!-- Textarea holds the previous prompt if a request was made -->
      <textarea id="prompt" name="prompt" placeholder="Write your prompt here...">{{ prompt }}</textarea><br/><br/>
      <button type="submit">Generate</button>
    </form>

    <!-- Displays the successfully generated text -->
    {% if result %}
      <div class="result">
        <h3>Generated (20-word limit):</h3>
        <p>{{ result }}</p>
      </div>
    {% endif %}

    <!-- Displays any errors encountered during the process -->
    {% if error %}
      <div class="result" style="border-color: #f99; background: #fff0f0;">
        <h3>Error</h3>
        <pre>{{ error }}</pre>
      </div>
    {% endif %}
  </body>
</html>
"""

# --- Route Definition ---
@app.route("/", methods=["GET", "POST"])
def index():
    """Handles both showing the form (GET) and processing user input (POST)."""
    
    # Logic for when the user submits the form.
    if request.method == "POST":
        # Get the 'prompt' text from the submitted form data and clean up whitespace.
        prompt = request.form.get("prompt", "").strip()
        
        # Validation: Check if the prompt is empty.
        if not prompt:
            # If empty, re-render the page with an error message.
            return render_template_string(HTML_PAGE, prompt=prompt, result=None, error="Prompt cannot be empty.")
            
        # --- Call to Backend API (TextGen Service) ---
        try:
            # Send a POST request to the textgen service's internal URL and /generate endpoint.
            # The 'timeout' prevents the frontend from waiting forever.
            resp = requests.post(
                f"{TEXTGEN_HOST}/generate",
                json={"prompt": prompt}, # Send the prompt as JSON data
                timeout=30
            )
        except requests.RequestException as e:
            # Catch network/connection errors (e.g., if the backend container is unreachable).
            return render_template_string(HTML_PAGE, prompt=prompt, result=None, error=str(e))
            
        # Check the HTTP status code of the backend's response.
        if resp.status_code != 200:
            # If the backend returned an error (e.g., 400, 500), display its error message.
            return render_template_string(HTML_PAGE, prompt=prompt, result=None,
                                          error=f"TextGen service error: {resp.status_code} - {resp.text}")
        
        # If successful (status 200), parse the JSON response from the backend.
        data = resp.json()
        result = data.get("generated", "")
        
        # Render the page, displaying the generated text.
        return render_template_string(HTML_PAGE, prompt=prompt, result=result, error=None)
        
    # Logic for a standard GET request (initial page load).
    else:
        # Render the empty form.
        return render_template_string(HTML_PAGE, prompt="", result=None, error=None)

# --- Application Entry Point ---
if __name__ == "__main__":
    # Runs the Flask server locally. '0.0.0.0' allows connections from outside 
    # the container's localhost, and '5000' is the internal port.
    app.run(host="0.0.0.0", port=5000)

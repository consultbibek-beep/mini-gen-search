The goal is to migrate:
Main repo: mini-gen-reference $\rightarrow$ mini-gen-search
Frontend Service: frontend-service-reference $\rightarrow$ frontend-service-search
Textgen Service: textgen-service-reference $\rightarrow$ textgen-service-rag

# 1. Clone the main repository and all submodules into the new directory name.
git clone --recurse-submodules https://github.com/consultbibek-beep/mini-gen-reference.git mini-gen-search

# 2. Change into the new project directory.
cd mini-gen-search

# 3. Remove the original GitHub connection (remote) for the main repo.
git remote rm origin
# Delete the .gitmodules file
rm .gitmodules
# Verify the remote is gone (optional).
git remote -v

Detach and Rename Submodule Directories
This ensures the directories are preserved on disk before renaming them.
A. Frontend Service (frontend-service-reference $\rightarrow$ frontend-service-search)

# 1. Change into the submodule directory and remove its original remote.
cd frontend-service-reference/
git remote rm origin
cd ..

# 2. Remove the submodule tracking from the main repo's index and .gitmodules.
# --cached leaves the directory/files on disk, allowing for the subsequent 'mv'.
git rm --cached frontend-service-reference

# 3. Rename the directory to the new project name.
mv frontend-service-reference frontend-service-search

# 4. Clean up the submodule's internal Git tracking entry (recommended). # did not match any file(s) known to git
git submodule deinit frontend-service-reference 

rm -rf .git/modules/frontend-service-reference

B. Textgen Service (textgen-service-reference $\rightarrow$ textgen-service-rag)
# 1. Change into the submodule directory and remove its original remote.
cd textgen-service-reference/
git remote rm origin
cd ..

# 2. Remove the submodule tracking from the main repo's index and .gitmodules.
git rm --cached textgen-service-reference

# 3. Rename the directory to the new project name.
mv textgen-service-reference textgen-service-rag

# 4. Clean up the submodule's internal Git tracking entry (recommended).
git submodule deinit textgen-service-reference
rm -rf .git/modules/textgen-service-reference

Complete Internal Git Cleanup
Run these commands to remove the internal Git data for the former submodules. This data is no longer necessary and is safe to delete.

Bash

# Clean up the internal Git data for the first former submodule
rm -rf .git/modules/frontend-service-reference

# Clean up the internal Git data for the second former submodule
rm -rf .git/modules/textgen-service-reference

# ... in parent directory: ~/workspace/mini-gen-search$
rm -rf .git
rm -rf frontend-service-search/.git
rm -rf textgen-service-rag/.git

3. Create New GitHub Repositories (Manual Step)
You must manually create three new empty GitHub repositories:

mini-gen-search
https://github.com/consultbibek-beep/mini-gen-search.git

frontend-service-search
https://github.com/consultbibek-beep/frontend-service-search.git

textgen-service-rag
https://github.com/consultbibek-beep/textgen-service-rag.git


# Create a .gitignore file *before* git init/git add 
# Use a .gitignore file to tell the parent repository to ignore the service folders immediately upon initialization.
echo "frontend-service-search/" > .gitignore
echo "textgen-service-rag/" >> .gitignore

# 1. Initialize and Push Service Repositories (Correct)
cd frontend-service-search
git init
git add .
git commit -m "Initial commit for standalone frontend service"
git branch -M main
git remote add origin https://github.com/consultbibek-beep/frontend-service-search.git
git push -u origin main
cd ..

# Repeat for textgen-service-rag
# 1. Initialize and Push Service Repositories (Correct)
cd textgen-service-rag
git init
git add .
git commit -m "Initial commit for standalone textgen service"
git branch -M main
git remote add origin https://github.com/consultbibek-beep/textgen-service-rag.git
git push -u origin main
cd ..

# 2. Initialize the Parent Repository (Corrected Steps)

# Create a .gitignore file *before* git init/git add
echo "frontend-service-search/" > .gitignore
echo "textgen-service-rag/" >> .gitignore

# Initialize the parent repository
git init

# Add and commit only the .gitignore and other top-level files
# The service folders are now ignored!
git add .
git commit -m "Initialized parent structure; ignoring service directories for submodule re-addition."
git branch -M main
git remote add origin https://github.com/consultbibek-beep/mini-gen-search.git
git push -u origin main

Remove "frontend-service-search/" from .gitignore
Remove "textgen-service-rag/" from .gitignore

# 1. Add the new frontend service as a submodule.
# NOTE: This command creates a new entry in .gitmodules and *clones* the repository.
git submodule add https://github.com/consultbibek-beep/frontend-service-search.git frontend-service-search

# 2. Add the new textgen service as a submodule.
git submodule add https://github.com/consultbibek-beep/textgen-service-rag.git textgen-service-rag

# 3. Commit the final .gitmodules changes and push to the new main repo.
git commit -m "Add frontend-service-search and textgen-service-rag as submodules with new URLs."
git push
















# ################################

https://github.com/consultbibek-beep/mini-gen.git
    https://github.com/consultbibek-beep/frontend-service.git
    https://github.com/consultbibek-beep/textgen-service.git

Repository,Purpose,Assumed Remote URL
Root,Orchestration & Deployment,https://github.com/consultbibek-beep/mini-gen.git
Service 1,Frontend Code,https://github.com/consultbibek-beep/frontend-service.git
Service 2,TextGen Code,https://github.com/consultbibek-beep/textgen-service.git

# Start
docker-compose up --build

http://localhost:8080/

# Stop all running docker
docker stop $(docker ps -q)

# Un-track the service folders in the root repo
git rm -r frontend-service
git rm -r textgen-service
git commit -m "chore: Preparing to add services as submodules"

# Add them back as submodules
git submodule add https://github.com/consultbibek-beep/frontend-service.git frontend-service
git submodule add https://github.com/consultbibek-beep/textgen-service.git textgen-service

# Commit the submodule references (the .gitmodules file is created here)
git commit -m "config: Added frontend and textgen as Git submodules"

# From Docker only to k8s

chmod +x deploy_instructions.sh
./deploy_instructions.sh

mini-gen/
├── frontend-service/
│   ├── app.py
│   ├── Dockerfile
│   ├── pyproject.toml
│   └── requirements.txt  <-- (Needed for Dockerfile)
├── textgen-service/
│   ├── app.py
│   ├── Dockerfile
│   ├── pyproject.toml
│   └── requirements.txt  <-- (Needed for Dockerfile)
├── k8s-manifests/
│   └── k8s-manifests.yaml  <-- (K8s Configs, uses $GROQ_API_KEY placeholder)
├── docker-compose.yml
├── .env                    <-- (Source of truth for GROQ_API_KEY)
└── deploy_instructions.sh  <-- (Automation script, uses envsubst)

# Stop k8s:
kubectl delete deployment frontend-deployment textgen-deployment
kubectl delete service frontend-service textgen
kubectl delete configmap textgen-config
kubectl get all

# CI/CD 
# Updated Project Str

mini-gen/
├── frontend-service/
│   ├── app.py
│   ├── Dockerfile
│   ├── pyproject.toml
│   ├── requirements.txt
│   └── .github/
│       └── workflows/
│           └── docker-publish.yml
│
├── textgen-service/
│   ├── app.py
│   ├── Dockerfile
│   ├── pyproject.toml
│   ├── requirements.txt
│   └── .github/
│       └── workflows/
│           └── docker-publish.yml
│
├── k8s-manifests/
│   └── k8s-manifests.yaml
├── docker-compose.yml
├── .env
└── deploy_instructions.sh

# Updated Project Str

The latest, consolidated project structure for your `mini-gen` setup is provided below. This structure incorporates all the final files and naming conventions confirmed during the troubleshooting process, particularly the separate stop script and the corrected CI/CD workflow names.

## Final Project Structure

```
mini-gen/
├── .env                          <-- Contains DOCKER_HUB and GROQ_API_KEY credentials
├── docker-compose.yml            <-- For local Docker development/testing
├── deploy_instructions.sh        <-- Main script to BUILD and DEPLOY to Kubernetes (using envsubst)
├── deploy_instructions_stop.sh   <-- New script to CLEAN UP all Kubernetes resources

├── k8s-manifests/
│   └── k8s-manifests.yaml        <-- Kubernetes manifests (uses $FRONTEND_TAG, $TEXTGEN_TAG, and $GROQ_API_KEY)

├── frontend-service/             <-- Separate GitHub Repository (Service 1)
│   ├── app.py
│   ├── Dockerfile
│   ├── pyproject.toml
│   ├── requirements.txt
│   └── .github/
│       └── workflows/
│           └── frontend-publish.yml  <-- FINAL CI/CD Workflow (with multi-arch, correct driver, and caching)

└── textgen-service/              <-- Separate GitHub Repository (Service 2)
    ├── app.py
    ├── Dockerfile
    ├── pyproject.toml
    ├── requirements.txt
    └── .github/
        └── workflows/
            └── textgen-publish.yml   <-- FINAL CI/CD Workflow (with multi-arch, correct driver, and caching)
```


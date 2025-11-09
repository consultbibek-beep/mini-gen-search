# Execution Steps:

To Start:
bibeks-MacBook-Air:~/workspace/mini-gen$ . ./deploy_instructions.sh
bibeks-MacBook-Air:~/workspace/mini-gen$ kubectl port-forward service/frontend-service 8080:80

To Stop:
bibeks-MacBook-Air:~/workspace/mini-gen$ . ./deploy_instructions_stop.sh

url:
http://localhost:8080/


# The goal is to migrate:
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


Here’s the **updated text-based project structure** MINI-GEN-SEARCH project:

MINI-GEN-SEARCH/
├── frontend-service-search/
│   ├── .github/
│   ├── .gitignore
│   ├── .python-version
│   ├── app.py
│   ├── main.py
│   ├── pyproject.toml
│   ├── README.md
│   ├── requirements.txt
│   ├── uv.lock
│   ├── Dockerfile
│   └── k8s-manifests/
│       └── k8s-manifests.yaml
│
├── textgen-service-rag/
│   ├── .github/
│   ├── .gitignore
│   ├── .python-version
│   ├── app.py
│   ├── main.py
│   ├── pyproject.toml
│   ├── README.md
│   ├── requirements.txt
│   ├── uv.lock
│   ├── Dockerfile
│
├── .gitignore
├── .gitmodules
├── .python-version
├── deploy_instructions_stop.sh
├── deploy_instructions.sh
├── docker-compose.yml
├── main.py
├── pyproject.toml
└── README.md



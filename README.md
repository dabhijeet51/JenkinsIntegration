# Jenkins Integration with Pytest Framework

This repository demonstrates a minimal setup for integrating a Python-based Pytest framework with Jenkins. 
It includes the essential configuration files and scripts to automate test execution through Jenkins pipelines.

# Project Structure

```
├── Jenkinsfile              # Jenkins pipeline configuration
├── conftest.py              # Pytest configuration and fixtures
├── requirements.txt         # Python dependencies (specific to python 3)
├── requirements-py2.txt     # Python 2 specific dependencies (legacy support)
└── script/
    ├── run_automated_tests.sh       # Activates virtual environments, installs dependencies, or sets environment variables.
```

# 1. Clone the Repository

```bash
git clone https://github.com/dabhijeet51/JenkinsIntegrationWithPytestFramework.git
cd JenkinsIntegrationWithPytestFramework
```

# 2. Set Up Python Environment

> Recommended: Use Python 3.x and a virtual environment.

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

# 3. Run Tests Locally

```bash
pytest script/
```

# Pytest Configuration

- `conftest.py` contains shared fixtures and hooks for Pytest.
- `script/` directory contains .sh file, used to automate the execution of test suites in a consistent and repeatable way—especially within CI/CD pipelines
- `requirements.txt` and `requirements-py2.txt` files are used to define list all the Python dependencies, required for project to run properly

# Jenkins Setup Instructions

1. Create a new Jenkins job (Pipeline type).
2. Connect to your GitHub repo.
3. Paste the `Jenkinsfile` contents into the pipeline script section.
4. Run the job to trigger automated testing.

# Requirements

- Python 3.x
- Jenkins with Pipeline plugin
- Git installed on Jenkins agent

# Additional Notes

- `requirements-py2.txt` is included for legacy Python 2 support.
- `results.xml` is generated for test reporting in Jenkins.

# Contributing

This is a minimal setup intended for demonstration.
- HTML reports
- Test coverage

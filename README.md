# StoryScape

## Overview
**StoryScape** is a generative AI-based iOS application built using **SwiftUI** that enables users to create pictorial stories in **Hindi** and **English**. The application leverages a fine-tuned **LLaMA 3.2 3B Instruct LLM** (deployed on AWS SageMaker) for Hindi story generation and **GPT-4o** for English stories. The stories can be generated in two distinct modes: **Prompt Only Mode** and **Image & Prompt Mode**. The user can also listen to the generated story.

---

## Table of Contents
1. [Frontend Features](#frontend-features)
2. [Backend Features and Architecture](#backend-features-and-architecture)
3. [Hindi Story Generation - LLM Details](#hindi-story-generation---llm-details)
4. [Tech Stack](#tech-stack)
5. [Backend Flow](#backend-flow)
6. [YouTube Demo](#youtube-demo)
7. [License](#license)
8. [Contact](#contact)

---


## Frontend Features

### 1. **Launch Screen**
- Displayed only on the first app launch or until the user logs in.
- After login, users are directly shown the **Home View**.

### 2. **Splash Screen**
- Displayed on subsequent app launches.

### 3. **Authentication**
- Handled using **Firebase** for secure login and signup.
- Multi-tenant support: Users can log out and log in with different accounts.

### 4. **Story Generation Modes**
#### **Prompt Only Mode**
- Users can enter a text prompt to generate a story along with relevant images.

#### **Image & Prompt Mode**
- Users provide both an image and a text prompt.
- The generated story is based on the prompt and image content/theme.
- **Optional Setting:** Users can choose whether to include AI-generated images in the story or use neutral images.

### 5. **Prompt Recommendations**
- Users receive **5 suggested prompts** based on the selected genre, language, and age group.
- **Reset Timing:**
  - Prompts reset daily at **12:00 AM**.
  - Prompts also reset when:
    - The user changes genres.
    - The user changes response language.
    - The user changes the age group for the story.

### 6. **Genres and Customization**
- Users can select or create their own genres and save them.
- Stories are generated based on the selected genre in **Settings**.

### 7. **Response Language**
- Supported languages for story generation:
  - **Hindi** (via fine-tuned LLaMA 3.2 3B Instruct LLM).
  - **English** (via GPT-4).

### 8. **Age Group Selection**
- Users can select an age group for the target audience from a predefined list.

### 9. **Story History**
- History of generated stories is displayed and categorized as:
  - **Today**
  - **Yesterday**
  - **Last 7 days**
  - **Last 30 days**
  - **Month-Year for ongoing year**
  - **Year for previous years (Archive)**
- **Search Functionality:**
  - Users can search for stories using keywords.
- **History Management:**
  - Users can clear the story history.

### 10. **Favorites**
- Users can mark stories as **Favorites** for easy access.
- Favorited stories are saved locally for offline access.

### 11. **Audio Narration**
- Below each generated story, there is an option to **generate audio**.
- The story is narrated via AI-generated voice.

### 12. **Prompt Saving**
- Users can save suggested prompts for later use.

---

## Backend Features and Architecture

### 1. **Django Application**
- The backend is built using **Django**.
- All frontend requests for story generation, user settings, and history management are managed by the Django REST API.

### 2. **Deployment on AWS EC2**
- The Django backend is hosted on an **AWS EC2** instance for reliable and scalable deployment.
- Instance security:
  - Proper security groups are configured to allow necessary ports (e.g., 80 for HTTP and 443 for HTTPS).
  - SSH access is secured with key pairs.

### 3. **Content Storage with AWS S3**
- **AWS S3** is used for storing user-uploaded images and generated story-related files.
- Buckets are configured with:
  - Public access restrictions for secure file storage.
  - Fine-grained access control using IAM roles.

### 4. **Containerization with Docker**
- The Django backend is dockerized to ensure consistency across different environments.
- Docker setup includes:
  - A `Dockerfile` that defines the necessary environment and dependencies.

### 5. **CI/CD Pipeline with Jenkins**
- A **Jenkins** pipeline is used for continuous integration and continuous deployment.
- Pipeline stages:
  1. **Build Stage:**
     - Jenkins pulls the latest changes from the GitHub repository.
     - Docker image is built for the Django application.
  2. **Test Stage:**
     - Unit tests and integration tests are executed to ensure stability.
  3. **Deploy Stage:**
     - The Docker container is deployed to the AWS EC2 instance.
     - Health checks are performed to ensure the backend is functioning correctly.

### 6. **Infrastructure as Code with Terraform**
- **Terraform** is used to define and provision infrastructure:
  - EC2 instance configuration.
  - S3 bucket creation.
  - Security group rules.
  - IAM roles for access management.
- Terraform ensures a reproducible and maintainable infrastructure setup.

---

## Hindi Story Generation - LLM Details

### 1. **Model Fine-Tuning**
- The Hindi story generation is powered by **LLaMA 3.2 3B Instruct LLM**.
- The model was fine-tuned on a dataset of Hindi stories, which was gathered through:
  - **Web Scraping:** Stories collected from various sources.
  - **Synthetic Data Generation:** Additional stories generated using existing smaller models.
- The fine-tuning process was conducted using **three-stage QLoRA (Quantized Low-Rank Adaptation)** with a **curriculum learning approach**.

### 2. **Three-Stage QLoRA Fine-Tuning Process**
- **Stage 1:**
  - Basic training with simple, short-length stories to warm up the model.
  - Loss function optimization using a lower learning rate.
- **Stage 2:**
  - Training on medium-length stories with intermediate complexity.
- **Stage 3:**
  - Advanced training on complex and longer stories.
  - Fine-grained tuning to enhance coherence, dialogue flow, and vocabulary richness.

### 3. **Curriculum Learning Approach**
- The model was trained progressively, starting from simpler to more complex data to:
  - Improve the model’s understanding of storytelling nuances.
  - Enhance the model’s performance on long-form story generation tasks.

### 4. **Deployment on AWS SageMaker**
- The fine-tuned model was deployed to **AWS SageMaker** to create a scalable and high-performance inference endpoint.
- Key configurations for deployment:
  - **Instance Type:** Optimized for large-scale LLM inference (e.g., GPU-accelerated instances).
  - **Auto-scaling:** Configured to handle varying workloads.
  - **Monitoring:** Integrated CloudWatch logs to monitor endpoint performance.

### 5. **Integration with Django Backend**
- The Django backend communicates with the SageMaker endpoint via REST API calls.
- The workflow:
  1. Frontend sends a request for Hindi story generation.
  2. Django backend forwards the request to the SageMaker endpoint.
  3. The inference response (story text) is processed and sent back to the frontend.
  4. Images (if applicable) are fetched and stored in **AWS S3**.

---

## Tech Stack

### **Frontend**
- **Framework:** SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel)
- **Authentication:** Firebase for login and signup.

### **Backend**
- **Framework:** Django (Python)
- **Deployment:** AWS EC2 (containerized with Docker)
- **Containerization:** Docker (used for backend consistency across environments)
- **Storage:** AWS S3 for storing images and generated content.

### **Continuous Integration/Continuous Deployment (CI/CD)**
- **Tool:** Jenkins
- **Pipeline Stages:** Build, Test, Deploy

### **Infrastructure Management**
- **Tool:** Terraform (for defining and provisioning cloud infrastructure).

### **Hindi Story Generation**
- **Model:** Fine-tuned LLaMA 3.2 3B Instruct.
- **Deployment:** AWS SageMaker (inference endpoint).
- **Fine-Tuning:** Three-stage QLoRA with curriculum learning approach.

### **English Story Generation**
- **Model:** GPT-4o.

### **Image Generation**
- **Tool:** DALL-E 3 (for generating images).

### **Audio Narration**
- **Tool:** TTS-1-HD (for generating high-quality AI narration).

### **Prompt Suggestions**
- **Tool:** GPT-4o-Mini (for generating prompt recommendations).

### **Image & Prompt Mode**
- In this mode, GPT-4o is used to analyze the user's uploaded image and integrate its context with the user’s prompt to generate a cohesive final prompt for story generation.

---

## Backend Flow
1. User sends a story generation request from the iOS app.
2. Django backend processes the request and determines the story generation mode (Prompt Only or Image & Prompt).
3. Backend communicates with the respective LLM API (AWS SageMaker for Hindi, GPT-4o API for English).
4. Story data and images (if applicable) are stored in AWS S3.
5. Response is sent back to the frontend for display.

---

## YouTube Demo
Watch a video demonstration of **StoryScape** [here (soon)](#).

---

## License
This project is licensed under the MIT License. See the `LICENSE` file for more information.

---

## Contact
If you have any questions or suggestions, feel free to create an issue or reach out via [devchopralinkedin@gmail.com].


# Amazons Game - Web Implementation

## Overview

This project is a web-based implementation of the classic abstract strategy board game, the **Game of the Amazons**. It provides a user interface allowing players to interact with the game directly within their web browser.

## How it Works

The application is built using the **Flutter** framework. Flutter's capabilities are leveraged to create the user interface and manage the game's state and logic.

The core development happens in Dart using Flutter, and then the application is specifically compiled for the **web platform** (`flutter build web`). This process generates standard HTML, CSS, and JavaScript files.

To make deployment simple and consistent, the project uses **Docker**. The provided `Dockerfile` sets up a multi-stage build:
1.  It first uses a Flutter environment to build the web application.
2.  It then copies the resulting static web files into a lightweight **Nginx** web server image.
3.  This final image contains only the compiled application and the server needed to host it, making it efficient to run.

Essentially, it's a Flutter application, compiled for the web, and served via Nginx within a Docker container.

## Technologies Used

*   **Frontend/Logic:** Flutter (Dart)
*   **Web Server:** Nginx
*   **Containerization:** Docker

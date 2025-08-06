# Gemini Commit

A simple yet powerful shell script that uses the Google Gemini API to automatically generate conventional commit messages from your staged changes. It helps you write clear, concise, and standardized commit messages with minimal effort.

## Features

*   **AI-Powered Commit Messages**: Leverages the Gemini API to analyze your code diffs and suggest relevant commit messages.
*   **Conventional Commits Format**: Generates messages following the [Conventional Commits](https://www.conventionalcommits.org/) specification.
*   **Interactive Confirmation**: Always asks for your approval before making a commit.
*   **Zero External Dependencies**: Written in pure Bash and uses common tools like `git`, `curl`, `sed`, and `awk`. No need to install `jq` or other external JSON parsers.
*   **Easy Setup**: Works with a simple `.env` file for your API key.

## Prerequisites

*   `git`
*   `curl`
*   A Bash-compatible shell.
*   A Google Gemini API Key. You can get one from Google AI Studio.

## Installation

1.  Clone this repository or simply download the `gemini-commit.sh` script.

2.  Make the script executable:
    ```bash
    chmod +x gemini-commit.sh
    ```

3.  Create a `.env` file from the example:
    ```bash
    cp .env.example .env
    ```

4.  Edit the `.env` file and add your Gemini API key:
    ```ini
    # .env
    GEMINI_API_KEY=YOUR_API_KEY_HERE
    ```

## Usage

1.  Stage the changes you want to commit:
    ```bash
    # Stage all changes
    git add .

    # Or stage specific files
    git add <your-file-1> <your-file-2>
    ```

2.  Run the script from your repository's root directory:
    ```bash
    ./gemini-commit.sh
    ```

3.  The script will display the suggested commit message from Gemini.

4.  Review the message and type `Y` (or just press Enter) to confirm and commit, or `n` to cancel.

    ```
    📥 Suggested commit message:
    --------------------------
    feat: Add Gemini-powered commit message generation

    This script automates the creation of conventional commit messages
    by sending staged diffs to the Gemini API and using the generated
    text for the commit.
    --------------------------
    Do you want to commit with this message? [Y/n]: y
    ✅ Commit successful.
    ```

## Pro Tip: Create a Git Alias

For even easier access, you can create a Git alias. Add the following to your global `~/.gitconfig` file, making sure to replace the path with the absolute path to the script.

```ini
[alias]
    ai-commit = "!/full/path/to/your/gemini-commit.sh"
```

Now you can simply run `git ai-commit` from anywhere inside your repository.
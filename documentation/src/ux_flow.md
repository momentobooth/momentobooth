# Screen Overview & Use

This page outlines the navigational structure of MomentoBooth. First, the general navigational flow is specified. Then, each screen is listed with what it is for, and which interactions it offers.

## High-Level User Flow

1. **[Start Screen](#start-screen)** → **[Navigation Screen](#navigation-screen)**
2. **[Navigation Screen](#navigation-screen)** → **[Capture Flow](#capture-flow-autonomous)** / **[Gallery](#gallery-screen)** / **Language Selection**
3. **[Capture Flow](#capture-flow-autonomous)** → **[Create Collage](#create-collage-screen)** (if applicable) → **[Share Screen](#share-screen--photo-details-screen)**
4. **[Share Screen](#share-screen--photo-details-screen)** → **[Start Screen](#start-screen)**

## Screen Definitions

### Start Screen

The initial "attract" mode of the application.

* **Visuals**: Displays a "Touch to Start" prompt.
* **Interactions**:
  * **Touch anywhere**: Transitions the user to the **Navigation Screen**.

### Navigation Screen

The central hub for all user activities.

* **Interactions**:
  * **Single Picture Button**: Initiates the autonomous capture flow for one photo.
  * **Collage Button**: Initiates the autonomous multi-capture flow for a collage.
  * **Gallery Button**: Navigates to the **Gallery Screen**.
  * **Change Language Button**: Opens the **Language Selection Dialog**.

### Capture Flow (Autonomous)

A transitional state where the app takes control.

* **Visuals**: Displays a countdown and live preview.
* **Behavior**: Once triggered, this process is fully autonomous. Users cannot interfere until the photo(s) are captured.
* **Transitions**:
  * Leads to the **Share Screen** after a single capture.
  * Leads to the **Create Collage Screen** after multiple captures.

### Create Collage Screen

The workspace for assembling a custom collage.

* **Visuals**: Displays an overview of all recently captured images.
* **Interactions**:
  * **Image Selection**: Toggle which photos to include in the final output.
  * **Continue Button**: Finalizes the selection and moves to the **Share Screen**.
  * **Retake Button**: Opens the **Retake Dialog**.

### Share Screen / Photo Details Screen

These screens provide the same final output actions for respectively new captures or gallery items.

* **Interactions**:
  * **Get QR Code**: Opens a **QR Dialog** containing a download link.
  * **Print**: Opens a **Print Dialog** to send the image to the configured printer.
  * **Back/Finish**:
    * From **Share Screen**: Returns the user to the **Start Screen**.
    * From **Photo Details**: Returns the user to the **Gallery Screen**.


### Gallery Screen

An archive of previous creations.

* **Visuals**: A grid overview of all saved collage outputs.
* **Interactions**:
  * **Select Image**: Opens the **Photo Details Screen** for the selected item.
  * **Back Button**: Returns the user to the **Navigation Screen**.

## Interactive Dialogs

These overlay components appear across various screens and close automatically upon action. Some can be dismissed by clicking/touching outside of them.
Here is a non-exhaustive overview.

| Dialog | Triggered From | Action |
| --- | --- | --- |
| **Language Selection** | Navigation Screen | Updates the app locale and closes. |
| **QR Dialog** | Share / Photo Details | Displays QR code; closes on dismissal. |
| **Print Dialog** | Share / Photo Details | Confirms print job and closes. |
| **Retake Dialog** | Share Screen | Asks whether the previous output file needs to be kept or deleted. |
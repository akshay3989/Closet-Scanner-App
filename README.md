
# Closet-Scanner-App
An iOS application built with **SwiftUI**, **RoomPlan**, **ARKit**, **RealityKit**, and **LiDAR** that scans a closet, generates a clean digital representation of the empty space by hiding detected contents, and calculates the closet's dimensions.
---

## Overview

ClosetScanner leverages Apple's RoomPlan framework and LiDAR-equipped iPhones to create an interactive scanning experience for closet spaces. The application captures the structural geometry of a closet, estimates its dimensions, and filters out detected objects to present a clean representation of the available storage space.

This project was developed as part of a technical challenge requiring a live iPhone demonstration.

---

## Features

* LiDAR-powered closet scanning using RoomPlan
* Real-time 3D room reconstruction
* Automatic width, depth, and height measurement
* Digital hiding of detected closet contents
* Clean empty-closet visualization
* Accuracy validation against manual tape measurements
* Modern SwiftUI user interface
* Modular MVVM-inspired architecture

---

## Technologies Used

* Swift 5
* SwiftUI
* RoomPlan
* ARKit
* RealityKit
* Combine
* Xcode
* iPhone LiDAR Scanner

---

## Requirements

### Hardware

* LiDAR-enabled iPhone

  * iPhone 12 Pro or newer Pro models
  * iPhone 17 Pro (used for development and testing)

### Software

* macOS
* Xcode 16+
* iOS 16 or later

---

## Project Structure

```text
ClosetScanner/
│
├── App/
├── Models/
├── Managers/
├── Views/
│   ├── Home/
│   ├── Scanner/
│   ├── Results/
│   └── Components/
├── Services/
├── Utilities/
├── Documentation/
└── Tests/
```

---

## Architecture

```
iPhone Camera + LiDAR
          │
          ▼
       ARKit
          │
          ▼
      RoomPlan
          │
          ▼
    CapturedRoom
          │
          ▼
Dimension Calculator
          │
          ▼
 SwiftUI Views
```

The application follows a modular architecture separating:

* UI components
* Business logic
* RoomPlan services
* Measurement calculations
* Validation workflow

---

## Application Workflow

1. Launch the application.
2. Start a RoomPlan scan.
3. Slowly scan the closet using the iPhone.
4. Finish the scan.
5. Generate a digital representation of the closet.
6. Hide detected objects while preserving structural surfaces.
7. Calculate and display:

   * Width
   * Depth
   * Height
8. Compare measured dimensions with tape-measure values.

---

## Accuracy Validation

To evaluate measurement performance:

1. Measure the closet manually using a tape measure.
2. Record width, depth, and height.
3. Perform five independent LiDAR scans.
4. Compare the application output with the manual measurements.
5. Calculate the absolute error for each dimension.

### Validation Metrics

* Average Error
* Maximum Error
* Mean Absolute Error (MAE)

Validation was performed under multiple conditions including:

* Good lighting
* Cluttered closet
* Different scanning angles
* Repeated scans

---

## Object Removal Strategy

The application does not modify the live camera image. Instead, it generates a clean digital representation of the closet by excluding RoomPlan-detected objects from the rendered model while preserving the structural geometry such as walls, floor, ceiling, and openings.

---

## Limitations

* Requires a LiDAR-enabled iPhone.
* Measurement accuracy depends on lighting, scan quality, and environmental conditions.
* Reflective or transparent surfaces may reduce reconstruction quality.
* Small or heavily occluded objects may not always be detected.
* Actual accuracy may vary depending on scanning technique and scene complexity.

---

## Future Improvements

* USDZ model export
* PDF measurement reports
* Closet volume estimation
* Automatic shelf detection
* AI-assisted storage layout recommendations
* Cloud synchronization
* Multi-room support

---

## Installation

1. Clone the repository.

```bash
git clone https://github.com/<your-username>/ClosetScanner.git
```

2. Open the project in Xcode.

3. Connect a LiDAR-enabled iPhone.

4. Build and run the application.

---

## Screenshots

Add screenshots here.

```
<img width="1206" height="2622" alt="89518" src="https://github.com/user-attachments/assets/981d1f32-7ccd-4d5f-b98b-1ce23da2c1f0" />

```

---

## Demo

The live demonstration includes:

* Scanning a real closet
* Displaying the reconstructed space
* Hiding detected contents
* Showing calculated dimensions
* Presenting validation against manual measurements

---

## Repository

```
ClosetScanner/
├── App
├── Models
├── Managers
├── Views
├── Services
├── Utilities
├── Documentation
└── Tests
```

---


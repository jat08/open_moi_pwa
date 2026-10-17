# OpenMOI

An open-source, cross-platform application and Progressive Web App (PWA) for measuring the **Moment of Inertia (MOI)**, **Swing Weight (SW)**, and **Twist Weight (TW)** of sports equipment—specifically pickleball paddles, tennis racquets, and custom athletic gear—using smartphone motion sensors.

---

## Primary Use Cases

- **Paddle & Racquet Measurement**: Measure Swing Weight (SW) and Twist Weight (TW) to understand power, maneuverability, and stability characteristics.
- **Customization & Weight Tuning**: Assist players, customizers, and equipment technicians in adding lead tape or weighting fixtures to match exact target MOI specifications.
- **Quality Control & Testing**: Measure and log batch samples to assess manufacturing consistency and verify product specifications.
- **Zero-Hardware Sensor Testing**: Turn any iOS, Android, or web browser device into a high-precision oscillation period timer without requiring external specialized lab hardware.

---

## Key Functionalities & Features

### 1. High-Precision Oscillation Period Measurement
- **Motion Sensor Capture**: Utilizes high-frequency device gyroscopes and accelerometers (via Native APIs, Generic Sensor API, and iOS Safari `DeviceMotion` interop) to accurately track rotational oscillation periods at 45° tilt orientations.
- **Sine-Wave Curve Fitting & Quality Scoring**: Performs non-linear curve fitting on raw motion data to calculate oscillation period $T$ and evaluate fit quality via a **Fit Residual Score**.
- **Fit Residual Exclusion**: Automatically flags or ignores poor-quality measurements where motion noise exceeds the threshold (default `1.5`).

### 2. Swing Weight (SW) & Twist Weight (TW) Calculation
- Converts raw oscillation periods into physical Moment of Inertia values ($kg \cdot cm^2$) based on calibrated rig parameters:
  - **Swing Weight (SW)**: Measured about the handle grip axis (higher inertia / longer oscillation periods).
  - **Twist Weight (TW)**: Measured about the longitudinal center axis (lower inertia / shorter oscillation periods).

### 3. Calibration & Rig Zeroing
- **Torsional Constant ($\kappa$) Calibration**: Two-object calibration workflow using known reference inertia standards (Object A and Object B) to determine the exact spring constant $\kappa$ of the test rig.
- **Tare Adapter Zeroing**: Zeroes out the tare inertia of paddle mounts and adapters (Tare PB, Tare TW, and Tare SW) to isolate the true net inertia of the paddle or racquet under test.

### 4. Statistical Filtering & Outlier Management
- **Low Margin Exclusion** (default `0.3%`): Applied to Swing Weight and higher inertia measurements (Object A, Object B, Tare SW) to flag cycles or measurement values deviating from the reference average.
- **High Margin Exclusion** (default `1.0%`): Applied to Twist Weight and lower inertia measurements (Tare PB, Tare TW) where relative period variation is naturally higher.
- **Cycle Trimming**: Supports auto-exclusion or manual trimming of the initial or final cycle in an oscillation measurement sequence.

### 5. Group Data Management & Export
- **Session Groups**: Organize measurements into named group folders by paddle model, player, or testing session.
- **Aggregate Statistics**: Computes group averages, standard deviation, min/max values, and sample counts.
- **Data Export**: Export complete measurement history, raw sensor data, and cycle statistics to CSV / JSON format for external analysis.

### 6. Web PWA & Cross-Platform Support
- Full Progressive Web App (PWA) support with web motion sensor permission handling for iOS Safari and mobile Chrome.
- Responsive layout supporting both mobile screens and desktop web browsers.

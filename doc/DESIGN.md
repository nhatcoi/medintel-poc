# MedIntel Digital Design Language

## 1. Overview & Creative North Star: "The Ethereal Caretaker"

This design system moves away from the sterile, rigid clinical interfaces of the past toward a "Creative North Star" we call **The Ethereal Caretaker**. 

For an elderly and chronic-disease patient demographic, cognitive load is the enemy. However, accessibility does not have to mean "basic." We break the standard template look by employing **Soft Minimalism**—an editorial approach that uses generous breathing room, intentional asymmetry, and layered depth to guide the eye. Instead of a grid of boxes, the UI feels like a series of soft, physical surfaces that prioritize the most critical health data. By using high-contrast typography against "frosted" surfaces, we create an experience that feels both authoritative (AI-powered) and deeply calming (human-centric).

---

## 2. Colors: Tonal Depth & Soul

The palette is rooted in a spectrum of healthcare blues and vitalizing greens, designed to soothe anxiety while providing clear status indicators.

### The "No-Line" Rule
To achieve a premium, high-end feel, **1px solid borders are strictly prohibited for sectioning.** We define boundaries through tonal shifts. A `surface-container-low` section sitting on a `background` provides all the definition a user needs without the visual noise of "boxes."

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of fine paper.
*   **Base:** `surface` (#f8f9fe)
*   **Structural Sections:** `surface-container-low` (#f1f4f9)
*   **Interactive Cards:** `surface-container-lowest` (#ffffff)
*   **Elevated Overlays:** `surface-bright` (#f8f9fe)

### The Glass & Gradient Rule
Standard flat colors feel "out-of-the-box." To elevate the experience:
*   **Glassmorphism:** For floating medication reminders or navigation bars, use `surface` colors at 80% opacity with a `20px` backdrop-blur. This allows the gentle hues of the background to bleed through, softening the interface.
*   **Signature Gradients:** Main CTAs (like "Take Medication") should utilize a subtle linear gradient from `primary` (#005eb6) to `primary-container` (#5f9efb). This adds a "jewel-like" quality that signals importance through depth rather than just brightness.

---

## 3. Typography: Editorial Authority

We use **Inter** to bridge the gap between technical precision and readable warmth.

*   **Display & Headline (The Narrative):** `display-lg` to `headline-sm` are used for daily summaries and primary health states. These are large and high-contrast (`on-surface` #2d333a) to ensure legibility for elderly users.
*   **Title (The Action):** `title-lg` is your primary interaction label. It’s bold and authoritative.
*   **Body (The Detail):** `body-lg` is the default for all patient-facing instructions. Never go below `body-md` for critical medication info.
*   **Labels (The Metadata):** Use `label-md` for secondary data (e.g., dosage timestamps).

**Signature Approach:** Use intentional white space around `display` text. A "Good Morning" greeting should have as much "air" as a headline in a premium magazine, reducing the patient's immediate cognitive stress.

---

## 4. Elevation & Depth: Tonal Layering

We convey hierarchy through light and shadow, mimicking natural environments to build trust.

*   **The Layering Principle:** Avoid shadows for static content. Achieve depth by stacking tokens. Place a `surface-container-lowest` card on a `surface-container-low` background. The subtle shift in hex code creates a "soft lift."
*   **Ambient Shadows:** For high-priority floating elements (e.g., an urgent pill reminder), use an extra-diffused shadow: `box-shadow: 0 20px 40px rgba(45, 51, 58, 0.06);`. The shadow color is a low-opacity version of `on-surface`, never pure black.
*   **The "Ghost Border" Fallback:** If accessibility requirements demand a container boundary, use a "Ghost Border": the `outline-variant` (#adb2ba) at **15% opacity**. It should be felt, not seen.

---

## 5. Components: Tactile & Intuitive

### Buttons (The "Touch-First" Standard)
*   **Primary:** Uses the `primary` to `primary-container` gradient. Large padding (1.5rem vertical) and `md` (1.5rem) roundedness to create a friendly, "pill-shaped" tactile target.
*   **Secondary:** `secondary-container` background with `on-secondary-container` text. No border.

### Medication Cards & Lists
*   **Rule:** **Forbid the use of divider lines.**
*   **Design:** Use vertical white space (32px minimum between items) and `surface-container-highest` backgrounds to group "Medication Name" and "Time" into a single cohesive unit. 
*   **Icons:** Use `tertiary` (#1c6d25) for success states (medication taken) to provide a gentle, health-focused green "glow."

### Input Fields
*   **Style:** Large, `surface-container-lowest` backgrounds with a `none` border. Focus states use a 2px `primary-dim` "Ghost Border" to softly highlight the active area.

### Progress Gauges (AI Insights)
*   Instead of thin lines, use thick, rounded strokes using `primary` and `surface-variant`. This mimics the "Apple Health" approach of bold, easy-to-read data visualization.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** use `xl` (3rem) rounding for large "daily summary" containers to make the AI feel approachable.
*   **Do** leverage `primary_fixed` for high-visibility interactive elements that must remain legible across all backgrounds.
*   **Do** prioritize "one-task-per-screen" layouts to minimize the cognitive load for elderly patients.

### Don’t:
*   **Don’t** use 100% opaque `outline` colors for borders. It creates a "boxed-in" clinical feeling.
*   **Don’t** use pure black (#000000) for text. Always use `on-background` (#2d333a) to maintain a softer, high-end editorial tone.
*   **Don’t** use small, "fiddly" icons. All icons should be encased in a touch target of at least 48x48dp.
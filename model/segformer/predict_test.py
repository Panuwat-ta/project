import os
import argparse

import cv2
import numpy as np
import torch

from mmseg.apis import init_model, inference_model


def run_inference(
    image_path: str,
    config_file: str,
    checkpoint_file: str,
    output_path: str,
    device: str = "cuda:0",
    min_area: int = 50,
    alpha: float = 0.5,
) -> None:
    """
    Run SegFormer forgery localization inference.

    Output:
        - Original image with forgery mask overlay
        - Bounding boxes around detected forged regions
    """

    print(f"[INFO] Config     : {config_file}")
    print(f"[INFO] Checkpoint : {checkpoint_file}")
    print(f"[INFO] Device     : {device}")
    print(f"[INFO] Image      : {image_path}")

    # ------------------------------------------------------------
    # 1. Load model
    # ------------------------------------------------------------
    model = init_model(
        config_file,
        checkpoint_file,
        device=device,
    )

    # ------------------------------------------------------------
    # 2. Inference
    # ------------------------------------------------------------
    result = inference_model(model, image_path)

    # ------------------------------------------------------------
    # 3. Read predicted segmentation mask
    # ------------------------------------------------------------
    if not hasattr(result, "pred_sem_seg"):
        raise RuntimeError("Inference result does not contain pred_sem_seg.")

    pred_mask = result.pred_sem_seg.data[0].detach().cpu().numpy()

    # Class 1 = forgery
    forgery_mask = (pred_mask == 1).astype(np.uint8) * 255

    # ------------------------------------------------------------
    # 4. Load original image
    # ------------------------------------------------------------
    original_image = cv2.imread(image_path)

    if original_image is None:
        raise RuntimeError(
            f"Cannot read image: {image_path}"
        )

    original_h, original_w = original_image.shape[:2]

    # Resize predicted mask back to original image size
    forgery_mask = cv2.resize(
        forgery_mask,
        (original_w, original_h),
        interpolation=cv2.INTER_NEAREST,
    )

    # ------------------------------------------------------------
    # 5. Remove tiny regions / noise
    # ------------------------------------------------------------
    num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(
        forgery_mask,
        connectivity=8,
    )

    filtered_mask = np.zeros_like(forgery_mask)

    for label_id in range(1, num_labels):
        area = stats[label_id, cv2.CC_STAT_AREA]

        if area >= min_area:
            filtered_mask[labels == label_id] = 255

    forgery_mask = filtered_mask

    # ------------------------------------------------------------
    # 6. Create red overlay
    # ------------------------------------------------------------
    output_image = original_image.copy()

    red_overlay = np.zeros_like(original_image)
    red_overlay[:, :, 2] = 255  # BGR -> Red

    mask_bool = forgery_mask > 0

    blended = cv2.addWeighted(
        original_image,
        1.0 - alpha,
        red_overlay,
        alpha,
        0,
    )

    output_image[mask_bool] = blended[mask_bool]

    # ------------------------------------------------------------
    # 7. Find detected forged regions
    # ------------------------------------------------------------
    contours, _ = cv2.findContours(
        forgery_mask,
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE,
    )

    detected_regions = []

    for contour in contours:
        area = cv2.contourArea(contour)

        if area < min_area:
            continue

        x, y, w, h = cv2.boundingRect(contour)

        detected_regions.append(
            {
                "x": x,
                "y": y,
                "width": w,
                "height": h,
                "area": area,
            }
        )

        cv2.rectangle(
            output_image,
            (x, y),
            (x + w, y + h),
            (0, 0, 255),
            3,
        )

        cv2.putText(
            output_image,
            "Forged Area",
            (x, max(y - 10, 20)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            (0, 0, 255),
            2,
            cv2.LINE_AA,
        )

    # ------------------------------------------------------------
    # 8. Calculate basic statistics
    # ------------------------------------------------------------
    total_pixels = forgery_mask.size
    forged_pixels = int(np.count_nonzero(forgery_mask))

    forgery_ratio = forged_pixels / total_pixels

    # ------------------------------------------------------------
    # 9. Save result
    # ------------------------------------------------------------
    output_dir = os.path.dirname(output_path)

    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    success = cv2.imwrite(output_path, output_image)

    if not success:
        raise RuntimeError(
            f"Failed to save output image: {output_path}"
        )

    # ------------------------------------------------------------
    # 10. Print result
    # ------------------------------------------------------------
    print()
    print("=" * 60)
    print("INFERENCE RESULT")
    print("=" * 60)
    print(f"Image size       : {original_w} x {original_h}")
    print(f"Forged pixels    : {forged_pixels:,}")
    print(f"Forgery ratio    : {forgery_ratio * 100:.2f}%")
    print(f"Detected regions : {len(detected_regions)}")
    print(f"Output           : {output_path}")
    print("=" * 60)

    if detected_regions:
        print("[RESULT] Forgery detected.")
    else:
        print("[RESULT] No significant forgery region detected.")


def main():
    parser = argparse.ArgumentParser(
        description="SegFormer image forgery localization inference"
    )

    parser.add_argument(
        "--config",
        type=str,
        required=True,
        help="Path to MMSegmentation config (.py)",
    )

    parser.add_argument(
        "--checkpoint",
        type=str,
        required=True,
        help="Path to model checkpoint (.pth)",
    )

    parser.add_argument(
        "--image",
        type=str,
        required=True,
        help="Path to input image",
    )

    parser.add_argument(
        "--output",
        type=str,
        default="result_pred.jpg",
        help="Path to output image",
    )

    parser.add_argument(
        "--device",
        type=str,
        default="cuda:0" if torch.cuda.is_available() else "cpu",
        help="Inference device",
    )

    parser.add_argument(
        "--min-area",
        type=int,
        default=50,
        help="Minimum forged region area in pixels",
    )

    parser.add_argument(
        "--alpha",
        type=float,
        default=0.5,
        help="Red overlay transparency (0-1)",
    )

    args = parser.parse_args()

    # ------------------------------------------------------------
    # Validate input files
    # ------------------------------------------------------------
    for name, path in [
        ("config", args.config),
        ("checkpoint", args.checkpoint),
        ("image", args.image),
    ]:
        if not os.path.isfile(path):
            parser.error(f"{name} not found: {path}")

    if not 0.0 <= args.alpha <= 1.0:
        parser.error("--alpha must be between 0 and 1")

    if args.min_area < 0:
        parser.error("--min-area must be >= 0")

    run_inference(
        image_path=args.image,
        config_file=args.config,
        checkpoint_file=args.checkpoint,
        output_path=args.output,
        device=args.device,
        min_area=args.min_area,
        alpha=args.alpha,
    )


if __name__ == "__main__":
    main()

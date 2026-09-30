# chat-screenshot-v1

Purpose: add a Chat/Screenshot domain. This is the domain with the largest gap
between what the product promises and what the model has ever seen.

## Why this dataset exists

`.agents/PRODUCT.md` names "สกรีนช็อตแชท" (chat screenshots) and
"สกรีนช็อตที่ดัดแปลงเนื้อหา" as a primary general-user use case, and
`AGENTS.md` states the scope is all scam images, not only bank slips.

Measured on 2026-09-29, the training manifest
(`/run/media/panuwat/USB/model/Det-Head/manifests/det-train-v3-audited.csv`,
95,635 rows) contains 10 datasets: authentic, psbattles, realtext, casia,
face, copymove, inpainting, splicing, imd2020, aiforge. None of them is a chat
or screenshot source. The 165-image Test-Cases set likewise has none.

The two existing chat/screenshot images were found inside
`Test-Cases/image-Authentic`, which is itself a misclassification: on
2026-09-29 the user confirmed `to1` is a LINE chat capture and `to11` is a
screen capture. Neither is a camera photo; both carry zero EXIF tags while the
other 9 files in that folder carry 12 each. They are now scored as the separate
`chatshot2` diagnostic.

Current measured behaviour on those 2 images
(`Det-Head/diagnostics_split_2026-09-29`):

    head    chatshot2 accuracy    mean score
    det2b   0/2                   0.7117
    det5a   0/2                   0.7558
    det6a   0/2                   0.8604

All three heads call both authentic chat captures manipulated, and the deployed
head already scores 0.71 mean on them. So this is a confirmed false-positive
source on a stated use case, not a hypothetical risk.

## Ground-truth rule

- Label 0 = an unmodified chat/screen capture that a real person received and
  believed genuine.
- Label 1 = a chat/screen capture whose content was altered to deceive: edited
  message text, edited sender name, edited timestamp, edited amount, pasted
  screenshot content, re-composed chat UI, or AI-generated/AI-restored content
  presented as a chat.
- A real conversation is authentic even when the topic is a scam. Scam topic
  without content manipulation is label 0, the same way a real bank slip is
  authentic regardless of the money involved.
- Uncertain files are excluded rather than relabelled.
- Keep the original capture. Do not re-crop, re-encode, or re-export, because
  re-encoding changes exactly the compression statistics the model keys on.

## Collection coverage

Capture the interfaces Thai users actually receive scams through, because the
failure mode is interface-specific:

- LINE chat, LINE official account/merchant chat, LINE OpenChat
- Facebook Messenger, Instagram DM, WhatsApp, Telegram
- SMS and banking-app notification screenshots
- Email and web-chat captures
- Desktop captures at several zoom levels and window sizes

Vary within each interface:

- light and dark theme
- Thai, English, and mixed text
- short and long conversations
- one bubble vs full screen, and partial scroll captures
- different device classes, since a screenshot resolution encodes the source
  device: 1080x1920 and 1170x2532 are typical phones, 1197x632 style sizes come
  from a different source

## Target size and split

- Minimum useful pilot: 300 images. Preferred initial version: 1,000+.
- Minimum 150 label1, because a manipulated-chat set smaller than that will let
  the model keep answering "authentic" and never learn the domain.
- Split by conversation and by capture session, never by random row: frames from
  the same conversation are near-duplicates and will inflate every metric.
- Suggested first version: 70% Train, 15% chat-Val, 15% chat-Test.
- The existing 2 images stay as `chatshot2` and must not enter any split.

## Model protocol

1. Validate byte and decoded-pixel duplicates, and duplicates against the
   protected `Test-Cases/image-Authentic` holdout using
   `Det-Head/validate_camera_authentic_incoming.py`.
2. Create a versioned manifest; never overwrite source files.
3. Precompute Det local tokens for approved Train/chat-Val images only.
4. Train from scratch with fixed seeds; do not initialise from a candidate that
   passed only on camera9.
5. Select architecture and hyperparameters on normal Val plus chat-Val.
6. Treat `chatshot2` as report-only, never as a gate, until it reaches a size
   where a two-image swing is distinguishable from noise.
7. Open Locked Test 44,031 only after a candidate passes camera9, pilot11,
   testcases, and chat-Val.

## Relationship to real-camera-authentic-v1

The two domains are separate and both are needed. Camera9 measures whether the
model stops flagging real photos; chat/screenshot measures whether it stops
flagging real chat captures. A candidate that fixes one while regressing the
other has traded one false-positive source for another, which is why both are
scored on every candidate in `Det-Head/run_det_loop.py`.

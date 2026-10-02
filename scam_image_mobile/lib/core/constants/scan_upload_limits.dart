// Current backend defaults in server/app/core/config.py. Backend validation
// remains authoritative if deployment configuration uses a lower limit.
const maxScanUploadBytes = 20 * 1024 * 1024;
const maxScanImagePixels = 100000000;

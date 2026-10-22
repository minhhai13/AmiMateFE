class ClaimDeviceRequest {
  const ClaimDeviceRequest({
    required this.deviceId,
    required this.pinCode,
  });

  final String deviceId;
  final String pinCode;

  Map<String, Object> toJson() => {
    'deviceId': deviceId.trim().toUpperCase(),
    'pinCode': pinCode,
  };
}

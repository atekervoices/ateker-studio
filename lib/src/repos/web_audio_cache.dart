class WebAudioCache {
  static final Map<int, String> _audioUrls = {};
  static final Map<int, String> _imageAudioUrls = {};

  static void setAudioUrl(int index, String? url) {
    if (url != null) {
      _audioUrls[index] = url;
    }
  }

  static String? getAudioUrl(int index) {
    return _audioUrls[index];
  }

  static void setImageAudioUrl(int index, String? url) {
    if (url != null) {
      _imageAudioUrls[index] = url;
    }
  }

  static String? getImageAudioUrl(int index) {
    return _imageAudioUrls[index];
  }
}

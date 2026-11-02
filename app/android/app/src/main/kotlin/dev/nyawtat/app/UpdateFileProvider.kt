package dev.nyawtat.app

import androidx.core.content.FileProvider

// Subclass sendiri supaya tidak bentrok dengan FileProvider milik plugin lain
// saat manifest digabung.
class UpdateFileProvider : FileProvider()

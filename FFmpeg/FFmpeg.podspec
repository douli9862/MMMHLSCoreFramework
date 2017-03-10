Pod::Spec.new do |s|
  s.name         = "FFmpeg"
  s.version      = "3.2"
  s.summary      = "The Kickflip platform provides a complete video broadcasting solution for your iOS application."
  s.homepage     = ""

  s.license      = 'Apache License, Version 2.0'

  s.author       = { "Chris Ballinger" => "chris@openwatch.net" }
  s.platform     = :ios, '7.0'
  s.source       = {  }

  s.source_files  = 'Kickflip', 'Kickflip/**/*.{h,m,mm,cpp}'
  s.resources = 'Kickflip/Resources/*'

  s.requires_arc = true

  s.libraries = 'c++
  s.dependency 'FFmpegWrapper', './FFmpegWrapper'

end

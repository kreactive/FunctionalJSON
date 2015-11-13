Pod::Spec.new do |s|
  s.name             = "FunctionalJSON"
  s.version          = "0.1.0"
  s.summary          = "FunctionalJSON is a fast and functional JSON library for Swift." 
  s.description      = <<-DESC
  Inspired by the play/scala JSON lib.
  Simple reads composition to build complex structures
  Full JSON validation & easy debugging
  Easy navigation into the JSON tree
  Simple syntax
  Fast !
                       DESC
  s.homepage         = "https://github.com/kreactive/FunctionalJSON"
  s.license          = 'MIT'
  s.author           = { "Antoine Palazzolo" => "a.palazzolo@kreactive.com" }
  s.source           = { :git => "https://github.com/kreactive/FunctionalJSON.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/antoine_p'
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'FunctionalJSON/*.swift'
  s.dependency 'FunctionalBuilder', '~> 0.1.0'
end

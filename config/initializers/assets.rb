# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add javascripts path to propshaft
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "javascripts")

# Add vendor javascript to propshaft
Rails.application.config.assets.paths << Rails.root.join("vendor", "javascript")

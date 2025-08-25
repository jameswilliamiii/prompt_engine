import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameField", "slugField"]
  static values = { isNewRecord: Boolean }

  connect() {
    // Auto-generate slug when name changes
  }

  generateSlug() {
    // Only auto-generate if slug is empty or if it's a new record
    if (!this.slugFieldTarget.value || this.isNewRecordValue) {
      const slug = this.nameFieldTarget.value
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '') // Remove special characters
        .replace(/\s+/g, '-') // Replace spaces with hyphens
        .replace(/-+/g, '-') // Replace multiple hyphens with single hyphen
        .replace(/^-|-$/g, '') // Remove leading/trailing hyphens
      this.slugFieldTarget.value = slug
    }
  }
}
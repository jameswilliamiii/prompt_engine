# Sprint 3: Version Control & History

## Sprint Goal
Implement comprehensive version control for prompts, allowing teams to track changes, compare versions, and rollback when needed. This provides the foundation for safe prompt iteration and deployment workflows.

## Design Principles
- Every change creates a new version
- Versions are immutable once created
- Clear visual diff presentation
- Simple rollback/restore workflow
- Environment tagging for deployment stages

## Tasks

### 1. Add Version Model & Migration (Priority: High)
- [ ] Create PromptVersion model
- [ ] Design schema with content, system_message, model_settings
- [ ] Add version number and timestamps
- [ ] Set up associations (belongs_to prompt)
- [ ] Create migration with proper indexes

### 2. Update Prompt Model for Versioning (Priority: High)
- [ ] Add has_many :versions association
- [ ] Implement current_version method
- [ ] Add callbacks to create versions on save
- [ ] Handle initial version creation
- [ ] Add version counter cache

### 3. Create Version History UI (Priority: High)
- [ ] Add versions controller with index/show actions
- [ ] Design version list view with timeline
- [ ] Display version metadata (number, author, timestamp)
- [ ] Add navigation from prompt to version history
- [ ] Style version cards/list items

### 4. Implement Diff Visualization (Priority: High)
- [ ] Create diff service for comparing versions
- [ ] Build diff view component
- [ ] Highlight additions/deletions
- [ ] Show side-by-side comparison
- [ ] Handle system message and settings changes

### 5. Add Version Restore Functionality (Priority: High)
- [ ] Add restore action to versions controller
- [ ] Create confirmation UI
- [ ] Implement version restoration logic
- [ ] Maintain version history on restore
- [ ] Add success notifications

### 6. Build Version Comparison Tool (Priority: Medium)
- [ ] Add compare action to controller
- [ ] Create version selector UI
- [ ] Build comparison view layout
- [ ] Show differences for all fields
- [ ] Include performance metrics comparison

### 7. Implement Environment Tagging (Priority: Medium)
- [ ] Add deployment_status to versions
- [ ] Create tag management UI
- [ ] Build tag selector component
- [ ] Add filtering by environment
- [ ] Show current production version

### 8. Add Version Metadata (Priority: Medium)
- [ ] Track who created each version
- [ ] Add change description field
- [ ] Implement auto-generated summaries
- [ ] Store browser/IP information
- [ ] Add version notes capability

### 9. Create Version Navigation (Priority: Low)
- [ ] Add previous/next version links
- [ ] Build version dropdown selector
- [ ] Implement keyboard shortcuts
- [ ] Add version search
- [ ] Create version permalinks

### 10. Build Version Activity Feed (Priority: Low)
- [ ] Create activity timeline view
- [ ] Show recent version changes
- [ ] Add filtering options
- [ ] Include rollback events
- [ ] Display deployment status changes

### 11. Add Version Permissions Hooks (Priority: Low)
- [ ] Create callbacks for authorization
- [ ] Add version creation hooks
- [ ] Implement restore permission checks
- [ ] Document permission integration
- [ ] Add configuration options

### 12. Implement Version Cleanup (Priority: Low)
- [ ] Add maximum versions setting
- [ ] Create cleanup rake task
- [ ] Build archive functionality
- [ ] Add version export
- [ ] Handle cascading deletes

### 13. Write Version Model Tests (Priority: High)
- [ ] Test version creation
- [ ] Test associations
- [ ] Test restoration logic
- [ ] Test diff generation
- [ ] Test cleanup rules

### 14. Add Version Controller Tests (Priority: High)
- [ ] Test index action
- [ ] Test show action
- [ ] Test restore action
- [ ] Test compare action
- [ ] Test authorization

### 15. Create Version System Tests (Priority: Medium)
- [ ] Test viewing version history
- [ ] Test restoring a version
- [ ] Test comparing versions
- [ ] Test environment tagging
- [ ] Test diff visualization

## Success Criteria
- Every prompt change creates a new version
- Version history is clearly displayed
- Can compare any two versions
- Can restore previous versions
- Environment tags help identify production versions
- Diff visualization clearly shows changes
- All tests passing
- Performance remains fast with many versions

## Technical Notes
- Consider using a diffing gem for text comparison
- Implement efficient version storage (store diffs vs full content)
- Index version queries properly
- Use database transactions for version operations
- Consider soft-delete for versions

## UI/UX Considerations
- Timeline visualization for version history
- Clear visual indicators for current version
- Intuitive diff highlighting (green/red)
- Confirmation dialogs for destructive actions
- Quick version switching interface
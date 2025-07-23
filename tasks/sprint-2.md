# Sprint 2: Admin UI & Basic Prompt CRUD

## Sprint Goal

Build a clean admin interface with left sidebar navigation and implement full CRUD functionality for
prompts with a modern UI using CSS3 and BEM methodology.

## Design Principles

- Neutral gray color scheme with subtle accent colors
- Clean, modern interface similar to shadcn/ui
- BEM (Block Element Modifier) CSS methodology
- Left sidebar navigation with main content area
- Mobile-responsive design

## Tasks

### 1. Create Admin Layout Structure (Priority: High)

- [x] Create admin layout file with sidebar and main content areas
- [x] Set up basic HTML structure with BEM classes
- [x] Configure layout inheritance for admin controllers

### 2. Design CSS Foundation (Priority: High)

- [x] Create CSS variables for color scheme (neutral grays, accent colors)
- [x] Set up typography scale and base styles
- [x] Create CSS reset/normalize styles
- [x] Define spacing system (margins, paddings)

### 3. Build Sidebar Navigation Component (Priority: High)

- [x] Create sidebar HTML structure with BEM classes
- [x] Style navigation items with hover/active states
- [x] Add navigation links (Dashboard, Prompts, Templates, Responses, Settings)
- [x] Implement current page highlighting
- [x] Add engine branding/logo area

### 4. Create Button Components (Priority: High)

- [x] Design primary button styles (create, save actions)
- [x] Design secondary button styles (cancel, back)
- [x] Design danger button styles (delete actions)
- [x] Add button size variants (small, medium, large)
- [x] Include hover and disabled states

### 5. Build Form Components (Priority: High)

- [x] Create input field styles with labels
- [x] Style textarea components
- [x] Design select/dropdown styles
- [x] Add form field error states
- [x] Create form layout helpers

### 6. Design Table Components (Priority: Medium)

- [x] Create table styles for listing prompts
- [x] Add table header styles
- [x] Design row hover effects
- [x] Include responsive table behavior
- [x] Add empty state design

### 7. Implement Prompts Index Page (Priority: High)

- [x] Create index action in prompts controller
- [x] Build index view with table layout
- [x] Display prompt attributes (name, status, model, created date)
- [x] Add "New Prompt" button
- [x] Include action buttons (view, edit, delete)

### 8. Create New/Edit Prompt Form (Priority: High)

- [x] Add new and create actions to controller
- [x] Add edit and update actions to controller
- [x] Build form partial with all prompt fields
- [x] Include form validation error display
- [x] Add cancel/save buttons

### 9. Implement Prompt Show Page (Priority: Medium)

- [x] Create show action in controller
- [x] Design detail view layout
- [x] Display all prompt attributes
- [x] Add edit/delete action buttons
- [x] Include back to list navigation

### 10. Add Delete Functionality (Priority: Medium)

- [x] Implement destroy action with proper redirects
- [x] Add confirmation dialog styling
- [x] Include flash message support
- [x] Style flash notifications

### 11. Create Card Components (Priority: Low)

- [x] Design card container styles
- [x] Add card header/body/footer sections
- [x] Create card variants (bordered, shadowed)
- [x] Use cards for show page layout

### 13. Implement Responsive Design (Priority: Medium)

- [x] Add responsive breakpoints
- [ ] Create mobile navigation toggle
- [x] Adjust table layout for mobile
- [ ] Test form layouts on mobile

### 14. Add Success/Error Notifications (Priority: Medium)

- [x] Style flash message containers
- [x] Create notification animations
- [x] Add auto-dismiss functionality
- [x] Position notifications appropriately

### 15. Write Controller Tests (Priority: High)

- [ ] Test index action
- [ ] Test new/create actions
- [ ] Test edit/update actions
- [ ] Test show action
- [ ] Test destroy action

### 16. Add System Tests (Priority: Medium)

- [ ] Test creating a new prompt
- [ ] Test editing an existing prompt
- [ ] Test deleting a prompt
- [ ] Test navigation between pages
- [ ] Test form validations

## Success Criteria

- Admin interface loads with sidebar navigation
- All navigation links present (prompts functional, others placeholders)
- Can create a new prompt with all fields
- Can view list of all prompts
- Can edit existing prompts
- Can delete prompts with confirmation
- Responsive design works on mobile
- All tests passing
- Clean, modern UI matching shadcn/ui aesthetic

## Technical Notes

- Use Rails form helpers with custom CSS classes
- Implement BEM naming convention strictly
- Ensure all styles are namespaced to prevent conflicts
- Use CSS Grid/Flexbox for layouts
- Follow accessibility best practices

## UI Color Palette

```css
/* Suggested color variables */
--color-gray-50: #f9fafb;
--color-gray-100: #f3f4f6;
--color-gray-200: #e5e7eb;
--color-gray-300: #d1d5db;
--color-gray-400: #9ca3af;
--color-gray-500: #6b7280;
--color-gray-600: #4b5563;
--color-gray-700: #374151;
--color-gray-800: #1f2937;
--color-gray-900: #111827;

--color-primary: #6366f1; /* Indigo */
--color-danger: #ef4444; /* Red */
--color-success: #10b981; /* Green */
```

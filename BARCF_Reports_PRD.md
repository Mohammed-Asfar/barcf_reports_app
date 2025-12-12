# BARCF Reports - Product Requirements Document (PRD)

## Project Overview

**Project Name:** BARCF Reports

**Project Type:** Windows Desktop Application (Offline-First)

**Description:** BARCF Reports is a local, offline issue/problem tracking and reporting system designed for managing employee issues, maintenance problems, and tracked incidents. The application supports role-based access control (Superadmin, Admin, User) with comprehensive CRUD operations, local SQLite database storage, and advanced reporting/export capabilities for Windows desktop environments.

---

## 1. Objectives

- Enable users to log and track issues/problems locally without internet connectivity on Windows desktop
- Provide role-based access control with three user tiers (Superadmin, Admin, User)
- Allow users to generate reports with filtering, sorting, and exporting capabilities
- Maintain data integrity through local SQLite database with proper authentication
- Support data export in multiple formats (PDF, Excel, Word/Docs)
- Enable password reset functionality at each role level
- Allow users to update and delete their own issues with full control
- Provide a professional Windows desktop UI with keyboard shortcuts and modern controls

---

## 2. User Roles & Permissions

### 2.1 Superadmin
- **Permissions:**
  - Create new Admin accounts with initial passwords
  - Reset passwords for Admin users
  - View all issues/reports across all users
  - Full CRUD on all issues (Create, Read, Update, Delete)
  - Access admin management panel
  - Manage system settings
  - View audit logs
  - Manage database and backups

### 2.2 Admin
- **Permissions:**
  - Create new User accounts with initial passwords
  - Reset passwords for User accounts
  - View all issues/reports created by users
  - Full CRUD on all issues (Create, Read, Update, Delete)
  - Generate reports and export data
  - Cannot manage Admins or Superadmin accounts
  - View audit logs for their managed users
  - Bulk operations on issues

### 2.3 User
- **Permissions:**
  - Create/log new issues
  - View own issues/reports
  - Edit own issues anytime
  - Delete own issues anytime
  - Generate personal reports with filtering and sorting
  - Export own reports in multiple formats
  - Cannot view other users' issues or manage accounts
  - Cannot access admin panels

---

## 3. Data Model & Database Schema

### 3.1 Users Table
```
users {
  id: INTEGER PRIMARY KEY AUTOINCREMENT
  username: TEXT UNIQUE NOT NULL
  passwordHash: TEXT NOT NULL
  role: TEXT NOT NULL (values: 'superadmin', 'admin', 'user')
  createdAt: TEXT
  updatedAt: TEXT
  createdByUserId: INTEGER (foreign key, nullable)
  deletedAt: TEXT (optional, for soft delete)
}
```

### 3.2 Issues/Reports Table
```
issues {
  id: INTEGER PRIMARY KEY AUTOINCREMENT
  sno: INTEGER
  name: TEXT NOT NULL
  empNo: TEXT NOT NULL
  problem: TEXT NOT NULL
  isIssueSorted: INTEGER (0=No, 1=Yes)
  materialsReplaced: TEXT
  attendedBy: TEXT
  date: TEXT NOT NULL (YYYY-MM-DD format)
  createdByUserId: INTEGER NOT NULL (foreign key → users.id)
  createdAt: TIMESTAMP
  updatedAt: TIMESTAMP
  updatedByUserId: INTEGER (foreign key → users.id, tracks who edited)
  deletedAt: TEXT (optional, for soft delete)
}
```

### 3.3 Audit Log Table (Optional, for security)
```
auditLogs {
  id: INTEGER PRIMARY KEY AUTOINCREMENT
  userId: INTEGER (foreign key → users.id)
  action: TEXT (CREATE, UPDATE, DELETE, LOGIN, PASSWORD_RESET)
  resourceType: TEXT (ISSUE, USER)
  resourceId: INTEGER
  details: TEXT (JSON with old/new values for updates)
  timestamp: TIMESTAMP
}
```

---

## 4. Core Features

### 4.1 Authentication & Login
- **Login Screen:**
  - Username and password fields
  - Local SQLite lookup and password verification
  - Offline-first authentication (no server required)
  - Error handling for invalid credentials
  - Remember last logged-in user (checkbox)
  - Session management (auto-logout after inactivity, optional)
  - Windows system tray integration

- **Password Requirements:**
  - Minimum 6 characters
  - Hash stored in database (using bcrypt or PBKDF2)
  - No plaintext passwords in database
  - Passwords must not be displayed in logs or error messages

### 4.2 User Account Management

#### Superadmin Panel - Create/Manage Admins
- View list of all Admin accounts in sortable DataGrid
- Create new Admin account
  - Input: username, initial password
  - Generate default password or allow custom password
  - Assign role: `admin`
  - Confirmation message on successful creation
- Reset Admin password
  - Select admin user from list
  - Generate new temporary password or allow custom reset
  - Confirm action with warning
  - Log action in audit logs
- Delete Admin account
  - Soft delete recommended (set deletedAt timestamp)
  - Confirmation dialog
  - Option to reassign issues to another admin

#### Admin Panel - Create/Manage Users
- View list of all User accounts (created by this admin) in sortable DataGrid
- Create new User account
  - Input: username, initial password
  - Assign role: `user`
  - Confirmation message
- Reset User password
  - Select user from list
  - Generate new temporary password or allow custom reset
  - Confirm action with warning
  - Log action in audit logs
- Delete User account
  - Soft delete recommended (set deletedAt timestamp)
  - Confirmation dialog
  - Option to archive user's issues or reassign

### 4.3 Reports/Issues Management

#### 4.3.1 Create Issue
- **Screen: New Issue Form / Dialog**
  - Fields: S.No., Name, Emp No., Problem, Is Issue Sorted? (Yes/No toggle), Materials Replaced (text area), Attended By, Date (date picker)
  - All fields required except Materials Replaced
  - Auto-populate current user as creator
  - Auto-set current date as default
  - Date picker with calendar UI
  - Form validation before submission
  - Submit button saves to SQLite
  - Success confirmation message
  - Option to create another issue or return to list
  - Keyboard shortcut: Ctrl+N for new issue

#### 4.3.2 View Reports List
- **Screen: Reports Dashboard**
  - Display reports in professional DataGrid format
  - Columns: S.No., Name, Emp No., Problem, Issue Sorted?, Materials Replaced, Attended By, Date, Actions
  - User sees only own reports
  - Admin/Superadmin see all reports (with creator user info)
  - Initially sorted by Date (newest first)
  - Issue count summary at top
  - Empty state message if no reports found
  - Status bar showing filtered/total count
  - Multi-select capability (Ctrl+Click, Shift+Click)
  - Context menu (right-click) for actions
  - Column resizing, reordering capabilities

#### 4.3.3 Search & Filter
- **Search Fields (multi-field search):**
  - Search by: Emp No., Name, Problem, Date
  - Real-time filtering as user types (with debounce)
  - Case-insensitive search
  - Can combine multiple search criteria
  - Clear search button
  - Search results count displayed
  - Advanced search dialog for complex queries
  - Save search filters as templates

- **Date Range Filter:**
  - "From Date" picker (calendar UI)
  - "To Date" picker (calendar UI)
  - Apply button to filter reports within range
  - Shows only issues created within selected date range
  - Clear date range button
  - Visual indicator showing active filters
  - Quick filter buttons (Today, Last 7 days, Last 30 days, Custom)

#### 4.3.4 Sort Options
- Sort by **Date** (Newest → Oldest, Oldest → Newest)
- Sort by **Emp No.** (Ascending/Descending)
- Sort by **Name** (A-Z, Z-A)
- Sort by **Issue Sorted Status** (Yes first, No first)
- Multi-level sort: Primary sort + Secondary sort (e.g., Date DESC, then Emp No. ASC)
- UI: Dropdown menu or sort buttons for quick selection
- Current sort order displayed visually with indicators
- Sort persistence during session
- Click column header to sort (standard DataGrid behavior)

#### 4.3.5 Edit Issue
- **User:** Can edit own issues anytime
  - Edit button visible on DataGrid or context menu
  - Double-click row to edit or Edit button
  - Pre-populate form with existing data
  - Update only changed fields
  - Track update timestamp (updatedAt)
  - Track which user made the edit (updatedByUserId)
  - Confirmation before saving changes
  - Success message on update
  - Keyboard shortcut: Ctrl+E to edit selected
  
- **Admin/Superadmin:** Can edit any issue
  - Full edit capability across all users' issues
  - Pre-populate form with existing data
  - Track which user made the edit (audit)
  - Confirmation before saving changes
  - Can view original creator and last editor info
  - Undo/Redo functionality (optional)

#### 4.3.6 Delete Issue
- **User:** Can delete own issues anytime
  - Delete button visible on DataGrid or context menu
  - Right-click context menu option
  - Confirmation dialog before deletion (cannot undo warning)
  - Deleted issues removed from database
  - Soft delete recommended (set deletedAt flag for recovery)
  - Success message after deletion
  - Deleted issues hidden from reports list
  - Keyboard shortcut: Delete key to delete selected
  
- **Admin/Superadmin:** Can delete any issue
  - Delete capability across all users' issues
  - Confirmation dialog before deletion
  - Track deletion in audit log
  - Can view deletion history (deletedAt timestamp)
  - Soft delete recommended for compliance/recovery
  - Option to permanently purge deleted records (admin only)
  - Bulk delete capability (select multiple, then delete)

### 4.4 Reports & Export

#### 4.4.1 Export Functionality
- **Export Formats:**
  - **PDF:** Formatted report with table, headers, footers, date range info, total records
  - **Excel (.xlsx):** Spreadsheet with all columns, proper formatting, date range, summary sheet, formulas
  - **Word (.docx):** Document format with table and metadata, professional formatting

- **Export Options:**
  - Apply current filters (search, date range, sort) to export
  - Choose export format (PDF, Excel, Word)
  - Option to include report title, generated date, user info, total records
  - Save to selected folder (file picker dialog)
  - Keyboard shortcut: Ctrl+S to export
  - Clipboard copy option (copy selected data to clipboard)
  - Direct printing option

- **Export UI:**
  - "Export" button on Reports toolbar
  - Export menu with format options
  - Dialog showing format options and current filters
  - Date range confirmation for export
  - Progress indicator during file generation
  - Success notification with file location
  - Option to open file after export in default application
  - Cancel button to abort export
  - Export history/log of all exports

#### 4.4.2 Report Customization
- Report title: "BARCF Reports - [User Name]" or "BARCF Reports - All Issues" (Admin view)
- Include: Date range applied, total records count, generated timestamp, user info
- Column headers in export matching display
- Professional formatting with borders, shading, fonts, color coding
- Page breaks for long reports
- Watermark or footer with "BARCF Reports" (optional)
- Company logo/branding option (configurable)

#### 4.4.3 Export Features
- Multi-format export ensures compatibility
- File naming: `BARCF_Reports_[Username]_[Date].pdf/xlsx/docx`
- Batch export for admin (multiple users' reports)
- Export preview option before final generation
- Retry mechanism if export fails
- File size check and warning for large exports
- Scheduled export (run at specific times) - optional
- Email export option (if mail configured)

---

## 5. UI/UX Architecture

### 5.1 Screen Hierarchy

```
Splash Screen / App Init
    ↓
Login Screen (Username + Password)
    ↓
    ├─ Superadmin Home
    │   ├─ Dashboard (Quick Stats, Charts)
    │   ├─ Admin Management (Create/Reset/Delete)
    │   ├─ All Reports View (with Search/Sort/Export)
    │   ├─ Audit Logs (Optional)
    │   ├─ Database Management
    │   ├─ Settings/Configuration
    │   └─ Logout / Exit
    │
    ├─ Admin Home
    │   ├─ Dashboard (Quick Stats)
    │   ├─ User Management (Create/Reset/Delete)
    │   ├─ All Reports View (with Search/Sort/Export)
    │   ├─ Settings
    │   └─ Logout / Exit
    │
    └─ User Home
        ├─ Create New Issue (Button/Menu)
        ├─ My Reports (Search/Sort/Filter/Export)
        ├─ Edit Issue (from DataGrid)
        ├─ Delete Issue (from DataGrid)
        ├─ Settings / Profile
        └─ Logout / Exit
```

### 5.2 Key Screens

**Screen 1: Login**
- Title: "BARCF Reports Login"
- Centered form with logo
- Username field with label
- Password field with show/hide toggle
- "Remember Me" checkbox
- Login button (primary action)
- Error message area (validation feedback)
- App logo/branding
- Version number and copyright
- Exit button

**Screen 2: User Reports Dashboard**
- Menu Bar:
  - File (Create Issue, Export, Print, Exit)
  - Edit (Edit, Delete, Select All)
  - View (Refresh, Clear Filters, Settings)
  - Help (About, Documentation)
- Toolbar with buttons:
  - New Issue (Ctrl+N)
  - Edit (Ctrl+E)
  - Delete (Delete key)
  - Refresh (F5)
  - Export (Ctrl+S)
  - Print (Ctrl+P)
- Status bar showing:
  - Total records, filtered records, selected records
  - Current user, timestamp
- Main area:
  - Header: "My Reports" / "All Reports"
  - Report count summary badge
  - Search bar (Emp No., Name, Problem, Date) with search icon
  - Date range pickers (From / To) with calendar icons
  - Sort dropdown (Date, Emp No., Name, Status)
  - Filter chips showing active filters with clear option
  - Professional DataGrid:
    - Columns: S.No., Name, Emp No., Problem, Issue Sorted?, Materials Replaced, Attended By, Date, Actions
    - Column headers clickable for sort
    - Alternating row colors for readability
    - Resize columns by dragging headers
    - Horizontal/vertical scrollbars
    - Multi-select with Ctrl+Click, Shift+Click
    - Context menu (right-click) with Edit, Delete, Export, Print options
  - Empty state message if no reports found
  - Status indicator for online/offline

**Screen 3: Create/Edit Issue Form / Dialog**
- Dialog or separate window layout
- Form title: "New Issue" / "Edit Issue [ID]"
- Form fields:
  - S.No. (auto-generated, read-only on edit)
  - Name (text input)
  - Emp No. (text input)
  - Problem (text input or textarea)
  - Is Issue Sorted? (radio buttons or toggle)
  - Materials Replaced (text area)
  - Attended By (text input)
  - Date (date picker with calendar button)
- Form validation feedback (inline red borders, error messages)
- Buttons:
  - Save button (primary action, Ctrl+S)
  - Cancel button (Escape key)
  - Reset button (clear form)
  - Help button
- Status message area (success/error feedback)

**Screen 4: Admin User Management**
- List of created users with user count summary
- Search users by username (search box)
- Toolbar with:
  - Create User button (primary)
  - Refresh button
  - Export Users button
- Professional DataGrid:
  - Username, Role, Created Date, Status, Last Active
  - Action buttons/menu: Reset Password, Delete, View Issues
  - Multi-select capability
  - Context menu options
- Confirmation dialogs for sensitive actions
- Success/error notifications (toast or message box)

**Screen 5: Export Dialog**
- Title: "Export Reports"
- Current filter summary section:
  - Search criteria, date range, record count, apply filters info
- Format selection radio buttons:
  - ○ PDF
  - ○ Excel (.xlsx)
  - ○ Word (.docx)
- Checkboxes for additional options:
  - ☐ Include report metadata
  - ☐ Include created date
  - ☐ Include creator info
  - ☐ Include footer with BARCF branding
- File location picker (Browse button to select save location)
- Filename preview
- Export button (primary action)
- Cancel button
- Progress bar during file generation
- Success message with file location link and "Open File" button

**Screen 6: Settings/Configuration**
- User info section:
  - Username, role, created date, last login
- Password change button (opens change password dialog)
- Application settings (for Superadmin):
  - Auto-logout timeout
  - Database backup location
  - Default export format
  - UI theme (Light/Dark mode)
- App version and build number
- Check for updates button
- About BARCF Reports section
- Logout button (prominent, warning color)
- Exit button

**Screen 7: Dashboard (Superadmin/Admin)**
- Quick stats cards:
  - Total Issues Count
  - Issues This Month
  - Total Users (Admin count for Superadmin)
  - Total Admins (Superadmin only)
- Charts and graphs:
  - Issues by date (line chart)
  - Issues by status (bar chart)
  - Top 5 employees with most issues
  - Issues trend (7 days, 30 days, custom range)
- Recent activities log
- Quick action buttons
- Export statistics option

---

## 6. Technical Stack

### 6.1 Technologies
- **Frontend Framework:** WPF (Windows Presentation Foundation) with C# or WinUI 3 (modern Windows UI)
  - Alternatively: WinForms for simpler UI
  - Recommended: WinUI 3 for modern, native Windows feel
- **Local Database:** SQLite (via SQLite NuGet package)
- **PDF Generation:** iTextSharp or PdfSharp
- **Excel Export:** ClosedXML or EPPlus (NuGet packages)
- **Word Export:** OpenXML SDK or DocX (NuGet packages)
- **Authentication:** Local password hashing (SHA256 or bcrypt via BCrypt.Net-Core)
- **File Management:** System.IO, Windows API for file dialogs
- **UI Components:** WPF/WinUI built-in controls, Material Design (optional)
- **State Management:** MVVM pattern with INotifyPropertyChanged
- **Date/Time:** System.DateTime, Globalization for date formatting
- **Logging:** Serilog or NLog for structured logging
- **Configuration:** appsettings.json or registry for app settings

### 6.2 Dependencies (.csproj / NuGet Packages)

```xml
<!-- Core Dependencies -->
<PackageReference Include="SQLite" Version="3.13.0" />
<PackageReference Include="System.Data.SQLite" Version="1.0.118.0" />

<!-- Export/Document Generation -->
<PackageReference Include="iTextSharp" Version="5.5.13.3" />
<!-- OR -->
<PackageReference Include="PdfSharp" Version="6.1.1" />
<PackageReference Include="ClosedXML" Version="0.96.1" />
<PackageReference Include="EPPlus" Version="7.0.0" />
<PackageReference Include="OpenXml.Xlsx" Version="1.0.9" />
<!-- OR -->
<PackageReference Include="DocX" Version="2.5.1" />

<!-- Security -->
<PackageReference Include="BCrypt.Net-Core" Version="1.6.0" />

<!-- Logging -->
<PackageReference Include="Serilog" Version="3.0.1" />
<PackageReference Include="Serilog.Sinks.File" Version="5.0.0" />

<!-- UI/UX (if using WinUI 3) -->
<PackageReference Include="Microsoft.WindowsAppSDK" Version="1.5.1" />
<!-- OR (if using WPF) -->
<PackageReference Include="MaterialDesignThemes" Version="4.10.0" />

<!-- Configuration -->
<PackageReference Include="Microsoft.Extensions.Configuration" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="8.0.0" />

<!-- Other Utilities -->
<PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
```

---

## 7. Security Considerations

- **Password Storage:** All passwords hashed using bcrypt (BCrypt.Net-Core) before storing in database
- **No Plaintext Storage:** Sensitive data never stored in plaintext anywhere
- **Local-Only Processing:** All authentication and data processing happens locally on device
- **Data Isolation:** Users see only their own data (enforced at service/repository layer, not just UI)
- **Role-Based Access Control:** Permissions checked before allowing any operation (backend validation)
- **Audit Logging:** Audit table logs all user actions (create, update, delete, login, password reset)
- **Database Encryption:** Consider SQLite encryption (SQLCipher) for sensitive environments
- **Input Validation:** All inputs validated before database operations
- **SQL Injection Prevention:** Use parameterized queries (ADO.NET prevents this by default)
- **Session Management:** Optional auto-logout after inactivity period with session token
- **Windows Integration:** Leverage Windows security features where possible
- **Secure deletion:** Overwrite file content before deleting backups

---

## 8. Error Handling & Validation

### 8.1 Input Validation
- **Username:** non-empty, alphanumeric with underscores/dots, 3-20 characters, unique in database
- **Password:** minimum 6 characters, enforced at account creation, no display in logs
- **Emp No.:** non-empty, alphanumeric, 1-20 characters
- **Name:** non-empty, text, 1-100 characters
- **Problem:** non-empty, text, 1-500 characters
- **Materials Replaced:** optional, text, max 500 characters
- **Attended By:** non-empty, text, 1-100 characters
- **Date:** valid date format (YYYY-MM-DD), not in future
- **All text fields:** max length enforced, whitespace trimmed

### 8.2 Error Scenarios
- **Invalid login credentials:** Show generic error "Invalid username or password", do not reveal which field is wrong
- **Duplicate username:** Show specific error "Username already exists, please choose another"
- **Database connection errors:** Show user-friendly message "Unable to access database, please try again"
- **Export failures:** Show error message with retry option and error details for logging
- **Missing required fields:** Highlight fields with red border and show inline error messages
- **Form validation:** Prevent submission of invalid forms (button disabled until valid)
- **File system errors:** Show error if cannot write to selected folder, suggest alternative location
- **Insufficient storage:** Warn user before exporting large datasets
- **Database locked:** Show error if database is locked by another process

### 8.3 Error Recovery
- Graceful degradation if features unavailable
- Automatic retry for transient failures
- User-friendly error messages (no technical jargon)
- Logging of errors for debugging (without sensitive data)
- Clear recovery actions (Retry, Cancel, Change settings)
- Error notification with severity indicator (Info, Warning, Error)

---

## 9. Testing Requirements

### 9.1 Unit Tests
- Database operations (CRUD on users and issues)
- Password hashing and verification logic
- Search and filter logic (various combinations)
- Sort functionality (single and multi-level)
- Export data generation (ensure correct format)
- Validation functions (username, password, emp no., date)
- Role-based permission checks
- Date range calculations

### 9.2 Integration Tests
- Complete login flow (valid/invalid credentials)
- Create/edit/delete issue operations (all roles)
- Role-based access control enforcement (prevent unauthorized access)
- Search and sort functionality combined
- Export generation and file validity
- User account creation/deletion by appropriate roles
- Password reset workflows
- Audit logging and retrieval
- Database transaction handling

### 9.3 Manual Tests
- UI responsiveness and responsiveness in different screen resolutions
- Export file quality (PDF, Excel, Word) - open in respective applications
- Data integrity after app restart
- Offline functionality verification
- Search performance with large datasets (10,000+ records)
- Date picker functionality
- Keyboard shortcuts work correctly
- Context menu operations
- DataGrid multi-select and bulk operations
- System tray integration (if implemented)
- Database file integrity check

### 9.4 Performance Tests
- Database query performance with 100,000+ records
- Search and filter response time
- Export generation time for large datasets
- Memory usage during normal operations
- UI responsiveness with large DataGrids
- Application startup time
- Concurrent user simulations (if multi-user)

---

## 10. Deployment & Release

### 10.1 Build Targets
- **Windows:** x86 (32-bit) and x64 (64-bit) builds
- **Minimum OS:** Windows 10 21H2 or Windows 11
- **.NET Framework:** .NET 6.0 or .NET 8.0 (latest recommended)
- **Architecture:** Self-contained deployment (includes .NET runtime)

### 10.2 Installation
- **Distribution Methods:**
  - MSI installer (WiX Toolset for professional installer)
  - ClickOnce deployment
  - Zip archive with executable
  - Portable executable (no installation required)
- **Installation Requirements:**
  - Administrator privileges recommended
  - Read/write access to application folder
  - SQLite database file location accessible
- **Installation Instructions:** Detailed step-by-step guide for users

### 10.3 Pre-Release Checklist
- ✅ All features implemented and tested
- ✅ No crash logs or unhandled exceptions
- ✅ Database migrations tested
- ✅ Performance optimized
- ✅ Security audit completed
- ✅ User documentation prepared
- ✅ Executable signed with digital certificate (optional, for security)
- ✅ Version number and build number updated
- ✅ Installer created and tested
- ✅ Release notes prepared

### 10.4 Data Backup & Migration
- Automatic backup of database on startup (optional)
- Manual backup function in Settings (Tools menu)
- Backup location configurable by Superadmin
- Data migration script if schema changes (future versions)
- Restore from backup functionality
- Clear upgrade instructions
- Database corruption recovery option

---

## 11. Future Enhancements (Out of Scope - Phase 2+)

- Cloud sync with optional server backend
- Multi-user network installation (shared database on network)
- Advanced analytics dashboard with charts and pivot tables
- Email notifications for issue updates
- Biometric authentication (Windows Hello)
- Voice-to-text for issue description input
- Attachment/image uploads for issues (photos, documents)
- Real-time collaboration features (multiple users viewing same data)
- Mobile companion app for Windows app sync
- Dark mode support (native Windows theme integration)
- Multi-language support (i18n)
- Custom report templates and report builder
- Issue assignment workflows with escalation
- Priority levels and SLA tracking
- Integration with external systems (ERP, ticketing systems)
- Database replication and sync across machines
- Automated report generation and scheduling
- Advanced audit trail with detailed change history

---

## 12. Success Metrics

- ✅ App launches without errors on Windows 10/11
- ✅ All CRUD operations work offline without internet
- ✅ Search, sort, filter perform correctly and responsively
- ✅ Export generates valid, openable files in all formats (PDF, Excel, Word)
- ✅ Role-based access enforced properly (no unauthorized access)
- ✅ Password reset works for all roles (Superadmin → Admin → User)
- ✅ Data persists correctly after app restart
- ✅ No data loss on unexpected app closure or crash
- ✅ User can edit/delete own issues without restrictions
- ✅ Admin can view and manage all user issues
- ✅ Database handles 100,000+ records without performance degradation
- ✅ All validation rules enforced
- ✅ Error messages are clear and helpful
- ✅ UI responsive and professional on different screen resolutions
- ✅ Keyboard shortcuts work as expected
- ✅ DataGrid operations (sort, multi-select) work correctly
- ✅ All export formats generate correctly formatted files

---

## 13. Project Milestones

| Phase | Tasks | Timeline |
|-------|-------|----------|
| **Phase 1: Setup & Design** | Project setup, database schema design, C# models, folder structure, UI design mockups | Week 1 |
| **Phase 2: Core & CRUD** | Login window, user management, issue CRUD, database operations, validation | Week 2 |
| **Phase 3: Reports & Export** | Search, sort, filter, export (PDF, Excel, Word), reports DataGrid, printing | Week 3 |
| **Phase 4: Admin Panels** | Superadmin/Admin screens, dashboard, user management, role-based navigation | Week 3 |
| **Phase 5: Polish & Testing** | UI polish, testing (unit, integration, manual), bug fixes, documentation | Week 4 |
| **Phase 6: Deployment** | MSI installer creation, final testing, release notes, user manual | Week 4 |

---

## 14. Glossary

| Term | Definition |
|------|-----------|
| **BARCF** | Project/Organization name for Reports management system |
| **Reports** | Collection of logged issues/problems/incidents tracked in the system |
| **Issues** | Individual problem entries with details (Emp No., Name, Problem, etc.) |
| **CRUD** | Create, Read, Update, Delete - basic database operations |
| **RBAC** | Role-Based Access Control - permission system based on user roles |
| **SQLite** | Local embedded relational database stored on device |
| **Hash/Hashing** | One-way encryption of passwords for secure storage |
| **Soft Delete** | Marking record as deleted (setting deletedAt) without removing from database |
| **Superadmin** | Highest privilege role, can manage admins and all issues |
| **Admin** | Middle privilege role, can manage users and all issues |
| **User** | Standard role, can create/manage own issues only |
| **Audit Log** | Record of all user actions for compliance and debugging |
| **Authentication** | Process of verifying user identity (login) |
| **Authorization** | Process of checking user permissions (what they can do) |
| **WPF** | Windows Presentation Foundation - Microsoft's UI framework |
| **WinUI 3** | Modern Windows UI framework for Windows 10/11 apps |
| **DataGrid** | Table control for displaying and editing data in tabular format |
| **MVVM** | Model-View-ViewModel - design pattern for WPF/Windows apps |
| **MSI** | Microsoft Installer - Windows installation package format |

---

## 15. Appendix

### A. Database Initialization Script (SQL)

```sql
-- Enable foreign keys (important for SQLite)
PRAGMA foreign_keys = ON;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  passwordHash TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('superadmin', 'admin', 'user')),
  createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deletedAt TEXT,
  createdByUserId INTEGER,
  FOREIGN KEY(createdByUserId) REFERENCES users(id)
);

-- Issues table
CREATE TABLE IF NOT EXISTS issues (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sno INTEGER,
  name TEXT NOT NULL,
  empNo TEXT NOT NULL,
  problem TEXT NOT NULL,
  isIssueSorted INTEGER DEFAULT 0 CHECK(isIssueSorted IN (0, 1)),
  materialsReplaced TEXT,
  attendedBy TEXT NOT NULL,
  date TEXT NOT NULL,
  createdByUserId INTEGER NOT NULL,
  updatedByUserId INTEGER,
  createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deletedAt TEXT,
  FOREIGN KEY(createdByUserId) REFERENCES users(id),
  FOREIGN KEY(updatedByUserId) REFERENCES users(id)
);

-- Audit logs table
CREATE TABLE IF NOT EXISTS auditLogs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  action TEXT NOT NULL CHECK(action IN ('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'PASSWORD_RESET')),
  resourceType TEXT NOT NULL CHECK(resourceType IN ('ISSUE', 'USER', 'AUTH')),
  resourceId INTEGER,
  details TEXT,
  timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(userId) REFERENCES users(id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_issues_createdByUserId ON issues(createdByUserId);
CREATE INDEX IF NOT EXISTS idx_issues_date ON issues(date);
CREATE INDEX IF NOT EXISTS idx_issues_empNo ON issues(empNo);
CREATE INDEX IF NOT EXISTS idx_issues_name ON issues(name);
CREATE INDEX IF NOT EXISTS idx_auditLogs_userId ON auditLogs(userId);
CREATE INDEX IF NOT EXISTS idx_auditLogs_timestamp ON auditLogs(timestamp);
```

### B. C# Models

**User Model:**
```csharp
public class User
{
    public int Id { get; set; }
    public string Username { get; set; }
    public string PasswordHash { get; set; }
    public string Role { get; set; } // 'superadmin', 'admin', 'user'
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
    public int? CreatedByUserId { get; set; }

    public User() { }

    public User(int id, string username, string passwordHash, string role, 
                DateTime createdAt, DateTime updatedAt, DateTime? deletedAt = null, 
                int? createdByUserId = null)
    {
        Id = id;
        Username = username;
        PasswordHash = passwordHash;
        Role = role;
        CreatedAt = createdAt;
        UpdatedAt = updatedAt;
        DeletedAt = deletedAt;
        CreatedByUserId = createdByUserId;
    }
}
```

**Issue Model:**
```csharp
public class Issue
{
    public int Id { get; set; }
    public int? Sno { get; set; }
    public string Name { get; set; }
    public string EmpNo { get; set; }
    public string Problem { get; set; }
    public int IsIssueSorted { get; set; } // 0 or 1
    public string MaterialsReplaced { get; set; }
    public string AttendedBy { get; set; }
    public string Date { get; set; } // YYYY-MM-DD
    public int CreatedByUserId { get; set; }
    public int? UpdatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }

    public Issue() { }

    public Issue(int id, int? sno, string name, string empNo, string problem,
                int isIssueSorted, string materialsReplaced, string attendedBy,
                string date, int createdByUserId, int? updatedByUserId,
                DateTime createdAt, DateTime updatedAt, DateTime? deletedAt = null)
    {
        Id = id;
        Sno = sno;
        Name = name;
        EmpNo = empNo;
        Problem = problem;
        IsIssueSorted = isIssueSorted;
        MaterialsReplaced = materialsReplaced;
        AttendedBy = attendedBy;
        Date = date;
        CreatedByUserId = createdByUserId;
        UpdatedByUserId = updatedByUserId;
        CreatedAt = createdAt;
        UpdatedAt = updatedAt;
        DeletedAt = deletedAt;
    }
}
```

**AuditLog Model:**
```csharp
public class AuditLog
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Action { get; set; } // CREATE, UPDATE, DELETE, LOGIN, PASSWORD_RESET
    public string ResourceType { get; set; } // ISSUE, USER, AUTH
    public int? ResourceId { get; set; }
    public string Details { get; set; }
    public DateTime Timestamp { get; set; }

    public AuditLog() { }

    public AuditLog(int id, int userId, string action, string resourceType,
                   int? resourceId, string details, DateTime timestamp)
    {
        Id = id;
        UserId = userId;
        Action = action;
        ResourceType = resourceType;
        ResourceId = resourceId;
        Details = details;
        Timestamp = timestamp;
    }
}
```

### C. Project Folder Structure

```
BARCFReports/
├── BARCFReports.csproj
├── App.xaml
├── App.xaml.cs
├── MainWindow.xaml
├── MainWindow.xaml.cs
├── appsettings.json
│
├── Models/
│   ├── User.cs
│   ├── Issue.cs
│   └── AuditLog.cs
│
├── Database/
│   ├── DatabaseHelper.cs            # Database operations
│   ├── DbSchema.cs                   # Schema initialization
│   └── DatabaseConnection.cs         # Connection management
│
├── Services/
│   ├── AuthService.cs
│   ├── UserService.cs
│   ├── IssueService.cs
│   ├── ExportService.cs              # PDF, Excel, Word export
│   ├── AuditService.cs
│   └── ValidationService.cs
│
├── ViewModels/
│   ├── LoginViewModel.cs
│   ├── DashboardViewModel.cs
│   ├── ReportsViewModel.cs
│   ├── UserManagementViewModel.cs
│   ├── IssueFormViewModel.cs
│   └── ExportViewModel.cs
│
├── Views/
│   ├── LoginWindow.xaml
│   ├── LoginWindow.xaml.cs
│   ├── DashboardWindow.xaml
│   ├── DashboardWindow.xaml.cs
│   ├── ReportsWindow.xaml
│   ├── ReportsWindow.xaml.cs
│   ├── UserManagementWindow.xaml
│   ├── UserManagementWindow.xaml.cs
│   ├── IssueFormWindow.xaml
│   ├── IssueFormWindow.xaml.cs
│   └── SettingsWindow.xaml
│
├── Utilities/
│   ├── Validators.cs
│   ├── DateFormatter.cs
│   ├── PasswordHasher.cs
│   ├── Constants.cs
│   ├── Logger.cs
│   └── DialogHelper.cs
│
├── Resources/
│   ├── Styles.xaml
│   ├── Colors.xaml
│   ├── Icons/
│   └── Fonts/
│
├── Assets/
│   ├── Logo.png
│   └── Icons/
│
├── Tests/
│   ├── UnitTests/
│   │   ├── ValidatorTests.cs
│   │   ├── DatabaseTests.cs
│   │   └── ServiceTests.cs
│   └── IntegrationTests/
│       └── WorkflowTests.cs
│
├── Documentation/
│   ├── UserManual.md
│   ├── TechnicalGuide.md
│   └── Installation.md
│
└── README.md
```

### D. Key Implementation Notes

**Password Hashing (using BCrypt):**
```csharp
using BCrypt.Net;

public class PasswordHasher
{
    public static string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password);
    }

    public static bool VerifyPassword(string password, string hash)
    {
        return BCrypt.Net.BCrypt.Verify(password, hash);
    }
}
```

**Date Formatting:**
```csharp
using System.Globalization;

public class DateFormatter
{
    public static string FormatDate(DateTime date)
    {
        return date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
    }

    public static DateTime ParseDate(string dateString)
    {
        return DateTime.ParseExact(dateString, "yyyy-MM-dd", CultureInfo.InvariantCulture);
    }
}
```

**DataGrid MVVM Binding (WPF Example):**
```csharp
public class ReportsViewModel : INotifyPropertyChanged
{
    private ObservableCollection<Issue> _issues;
    public ObservableCollection<Issue> Issues
    {
        get => _issues;
        set
        {
            _issues = value;
            OnPropertyChanged(nameof(Issues));
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;

    protected void OnPropertyChanged(string propertyName)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
```

---

## 16. Windows-Specific Features

### 16.1 Integration with Windows
- System tray icon with context menu (minimize to tray)
- Taskbar integration and notifications
- Windows file dialogs for open/save
- System default applications for opening exported files
- Windows Event Viewer integration for logging
- Windows Registry for application settings (optional)

### 16.2 Keyboard Shortcuts
- Ctrl+N - New Issue
- Ctrl+E - Edit selected issue
- Ctrl+S - Export report
- Ctrl+P - Print
- Ctrl+F - Find/Search
- Delete - Delete selected
- F5 - Refresh data
- Escape - Cancel/Close dialog
- Alt+F4 - Exit application

### 16.3 User Experience
- Modern Fluent Design System (Windows 11 style)
- Taskbar progress for long-running operations
- Toast notifications for success/error messages
- Native file pickers and dialogs
- Drag-and-drop support for data
- Responsive UI with high DPI scaling support

---

## 17. Support & Maintenance

- **Documentation:** User manual, technical guide, installation instructions
- **Bug Fixes:** Prioritized bug fixes for critical issues
- **Updates:** Regular updates for security patches and minor features
- **Support Channel:** Email or help documentation
- **User Forum:** Optional community support

---

**Document Version:** 1.0  
**Last Updated:** December 12, 2025  
**Author:** Product Team  
**Status:** Final / Ready for Development

---

**Prepared By:** [Team Name]  
**Approved By:** [Approval Authority]  
**Distribution:** Development Team, Project Manager, Stakeholders

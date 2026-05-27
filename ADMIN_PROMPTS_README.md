# Admin Prompts Management System

## Overview

The Admin Prompts Management System allows administrators to dynamically add, edit, and delete recording prompts with associated images. All data is stored in Firebase Firestore, and images are stored in Firebase Storage.

## Features

### 1. **Dynamic Prompt Management**
- **Add Prompts**: Create new recording prompts with text and category
- **Edit Prompts**: Update existing prompt text, category, and images
- **Delete Prompts**: Remove prompts from the system
- **Categorization**: Organize prompts by topic (Animals, Food, Nature, Objects, People)

### 2. **Image Management**
- **Upload Images**: Upload images directly to Firebase Storage
- **Image Previews**: Display image previews in the admin interface
- **Dynamic Fetching**: Images are fetched dynamically from Firebase Storage
- **URL Support**: Option to use image URLs for quicker setup

### 3. **Firestore Integration**
- **Data Persistence**: All prompts are stored in Firestore with metadata
- **Admin Tracking**: Each prompt records who created/updated it and when
- **Real-time Updates**: UI updates in real-time as prompts are modified

## Architecture

### New Files Created

1. **`lib/src/repos/admin_prompts_repository.dart`**
   - Manages all Firestore and Firebase Storage operations
   - Handles CRUD operations for prompts
   - Manages image uploads and downloads

2. **`lib/src/admin_web/admin_prompts_page.dart`**
   - Main admin panel UI for managing prompts
   - Grid-based display of all prompts
   - Integration with AdminPromptsRepository

3. **`lib/src/admin_web/add_prompt_dialog.dart`**
   - Dialog for adding/editing prompts
   - Image selection and preview
   - Form validation and submission

### Updated Files

1. **`lib/src/admin_web/admin_web_app.dart`**
   - Added MultiProvider for dependency injection
   - Registered AdminPromptsRepository
   - Added new route for AdminPromptsPage

2. **`lib/src/admin_web/dashboard_page.dart`**
   - Added "Manage Prompts" button in AppBar
   - Navigation to AdminPromptsPage

## Firebase Firestore Schema

### Collection: `admin_prompts`

```json
{
  "text": "string (prompt text)",
  "topic": "string (enum: animals, food, nature, objects, people)",
  "imageUrl": "string (Firebase Storage download URL)",
  "imageFileName": "string (filename of uploaded image)",
  "createdAt": "timestamp",
  "createdBy": "string (admin UID)",
  "updatedAt": "timestamp (optional)"
}
```

### Firebase Storage Structure

```
admin_prompt_images/
  {userId}/
    {imageFileName}
```

## Usage

### Accessing the Admin Panel

1. Navigate to the Admin Dashboard
2. Click the **"Manage Prompts"** button in the top-right
3. You'll be taken to the Admin Prompts management page

### Adding a New Prompt

1. Click **"Add Prompt"** button
2. Enter the prompt text
3. Select a topic category
4. Choose an image (via URL or file selection)
5. Click **"Add Prompt"** to submit

### Editing a Prompt

1. Find the prompt card in the grid
2. Click the **"Edit"** button
3. Modify the text, category, or image
4. Click **"Save Changes"**

### Deleting a Prompt

1. Find the prompt card in the grid
2. Click the **"Delete"** button
3. Confirm the deletion

## Data Model

### AdminPromptItem Class

```dart
class AdminPromptItem {
  String id;                      // Firestore document ID
  String text;                    // Prompt text
  ImagePromptTopic topic;         // Category
  String? imageUrl;               // Firebase Storage URL
  String imageFileName;           // Filename in storage
  DateTime createdAt;             // Creation timestamp
  String createdBy;               // Admin UID who created it
}
```

### ImagePromptTopic Enum

```dart
enum ImagePromptTopic {
  animals('Animals'),
  food('Food'),
  nature('Nature'),
  objects('Objects'),
  people('People');
}
```

## Integration with User App

The prompts created in the admin panel are automatically available to users through:

1. **Update ImagePromptsRepository**: Modify `lib/src/repos/image_prompts_repository.dart` to fetch from Firestore instead of local assets
2. **User UI**: The prompts will appear in the main recording flow

### Example Integration

```dart
// In image_prompts_repository.dart, replace initFromAssetFile() with:
Future<void> initFromFirestore() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('admin_prompts')
        .get();
    
    _imagePrompts.clear();
    for (final doc in snapshot.docs) {
      _imagePrompts.add(AdminPromptItem.fromFirestore(doc));
    }
    
    notifyListeners();
  } catch (e) {
    developer.log('Error loading prompts from Firestore: $e');
  }
}
```

## Security Considerations

### Firestore Rules (Recommended)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin only can read/write prompts
    match /admin_prompts/{document=**} {
      allow read: if request.auth.uid != null;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

### Storage Rules (Recommended)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Admin images are publicly readable but only admin can write
    match /admin_prompt_images/{allPaths=**} {
      allow read;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

## Future Enhancements

1. **File Picker Integration**: Add `file_picker` package for native file selection
2. **Batch Operations**: Import/export prompts as JSON
3. **Image Processing**: Auto-resize and optimize images before upload
4. **Analytics**: Track prompt usage statistics
5. **Versioning**: Keep history of prompt changes
6. **Multi-language Support**: Translate prompts into different languages
7. **Scheduling**: Schedule when prompts become active/inactive

## Troubleshooting

### Images not appearing in preview
- Ensure Firebase Storage rules allow public read access
- Check that the image URL is correctly formatted
- Verify the image is uploaded to the correct path

### Prompts not saving to Firestore
- Check Firebase connection and authentication
- Verify Firestore rules allow admin write access
- Check browser console for error messages

### Performance issues
- Implement pagination for large numbers of prompts
- Add image caching in the UI
- Consider Cloud Storage CDN for image delivery

## Dependencies

The implementation uses:
- `cloud_firestore`: For data storage
- `firebase_storage`: For image storage
- `firebase_auth`: For authentication
- `provider`: For state management
- `flutter`: Core framework

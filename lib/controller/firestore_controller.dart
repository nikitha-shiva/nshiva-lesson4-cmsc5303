import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lesson4/model/photomemo.dart';

class FirestoreController {
  static const photoMemoCollection = 'photomemo_collection';

  static Future<String> addPhotoMemo({required PhotoMemo photoMemo}) async {
    DocumentReference ref = await FirebaseFirestore.instance
        .collection(photoMemoCollection)
        .add(photoMemo.toFirestoreDoc());
    return ref.id;
  }

  static Future<List<PhotoMemo>> getPhotoMemoList({
    required String email,
  }) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(photoMemoCollection)
        .where(DocKeyPhotoMemo.createdBy.name, isEqualTo: email)
        .orderBy(DocKeyPhotoMemo.timestamp.name, descending: true)
        .get();
    var result = <PhotoMemo>[];
    for (var doc in querySnapshot.docs) {
      if (doc.data() != null) {
        var document = doc.data() as Map<String, dynamic>;
        var p = PhotoMemo.fromFirestoreDoc(doc: document, docId: doc.id);
        if (p.isValid()) result.add(p);
      }
    }
    return result;
  }

  static Future<void> updatePhotoMemo(
      {required String docId, required Map<String, dynamic> update}) async {
    await FirebaseFirestore.instance
        .collection(photoMemoCollection)
        .doc(docId)
        .update(update);
  }

  static Future<List<PhotoMemo>> getSharedWithList({required String email}) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
    .collection(photoMemoCollection)
    .where(DocKeyPhotoMemo.sharedWith.name, arrayContains: email)
    .orderBy(DocKeyPhotoMemo.timestamp.name, descending: true)
    .get();

    var result = <PhotoMemo>[];
    for ( var doc in querySnapshot.docs){
      if(doc.data() != null) {
        var document = doc.data() as Map<String, dynamic>;
        var p = PhotoMemo.fromFirestoreDoc(doc: document, docId: doc.id);
        result.add(p);
      }
    }
    return result;
  }

  static Future<void> deleteDoc({required String docId}) async {
    await FirebaseFirestore.instance.collection(photoMemoCollection).doc(docId).delete();
  }

}

'use strict';
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');

const {Storage} = require('@google-cloud/storage');

// Creates a client
const storage = new Storage({
  projectId: "ourcampus-73",
});

const bucket = storage.bucket("ourcampus-73.appspot.com");

var serviceAccount = require("./ourcampus-73-firebase-adminsdk-zd2bg-0eea13e112.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://ourcampus-73.firebaseio.com/"
});


// Take the text parameter passed to this HTTP endpoint and insert it into the
// Realtime Database under the path /messages/:pushId/original
exports.addMessage = functions.https.onRequest(async (req, res) => {
  // Grab the text parameter.
  const original = req.query.text;
  // Push the new message into the Realtime Database using the Firebase Admin SDK.
  const snapshot = await admin.database().ref('/messages').push({original: original});
  // Redirect with 303 SEE OTHER to the URL of the pushed object in the Firebase console.
  res.redirect(303, snapshot.ref.toString());
});


// Cut off time. Child nodes older than this will be deleted.
const CUT_OFF_TIME = 864000000; // 10 days in milliseconds.

/**
 * This database triggered function will check for child nodes that are older than the
 * cut-off time. Each child needs to have a `eventtime` attribute.
 */
exports.deleteOldItems = functions.database.ref('/Events/{pushId}').onWrite(async (change) => {
  const ref = change.after.ref.parent; // reference to the parent
  const now = Date.now();
  const cutoff = now - CUT_OFF_TIME;
  const oldItemsQuery = ref.orderByChild('eventtime').endAt(cutoff);
  const snapshot = await oldItemsQuery.once('value');
  // create a map with all children that need to be removed
  const updates = {};
  snapshot.forEach(child => {
    updates[child.key] = null;
  });
  // execute all updates in one go and return the result to end the function
  return ref.update(updates);
});

// function to delete image from storage upon deletion of event
exports.deleteOldImages = functions.database.ref('/Events/{pushId}').onDelete(async (change) => {
  const id = change.key
  const filePath = `events/${id}.png`;
  const file = bucket.file(filePath);
  file.delete().then(() => {
       return console.log(`Successfully deleted photo with path ${filePath}`)

   }).catch(err => {
       return console.error(`Failed to remove photo, error: ${err}`)
   });
});

// function to delete old feeds when an event is deleted
exports.deleteOldFeeds = functions.database.ref('/Events/{pushId}').onDelete((snapshot, context) => {
  const id = snapshot.key;
  return admin.database().ref('Feed/' + id).remove();
});


// function to send notifications
exports.sendNotification = functions.database.ref('Users/{pushId}/Notifications').onWrite( async (snapshot, context) => {
  const id = context.params.pushId;

  var ref = admin.database().ref('Users/' + id);

  ref.once('value').then(function(snapshot) {
    const token = snapshot.child('token').val();
    var headers = ["Ayoooo", "Yerrrr", "Vibe check"]
    const ti = headers[Math.floor(Math.random()*headers.length)];
    var payload = { notification:
      { title: ti,
      body: "You've just been invited to an event."}
    };
    admin.messaging().sendToDevice(token, payload)
    return console.log("Sent to:", token)
  })
  .catch(function(error) {
    return console.log("Error getting tokens:", error);
  })
});

exports.reportAlert = functions.database.ref('ReportedEvents/{pushId}').onWrite( async (snapshot, context) => {
  var payload = { notification:
    { title: "Event has been reported",
    body: "Someone has just reported an event."}
  };

  var ref = admin.database().ref('Users/Db4sWy7ivBMJiJk5EXrNL1gsPx32');
  ref.once('value').then(function(snapshot) {
    const token = snapshot.child('token').val();
    admin.messaging().sendToDevice(token, payload)
    return console.log("Event report has been sent to Raf")
  })
  .catch(function(error) {
    return console.log("Error getting token:", error);
  })
});

exports.OnSeatsAvailable = functions.database.ref('/Spring20/{ClassId}/seats_available').onUpdate( (change, context) => {

    const before = change.before.val();
    const after = change.after.val();

    if (after > before) {
        const id = context.params.ClassId;
        var ref = admin.database().ref('Subscriptions/' + id);
        ref.once('value', function(snapshot) {
          var uids = [];
          snapshot.forEach(function(childSnapshot) {
            var key = childSnapshot.key;
            uids.push(key);
          })
          var ref2 = admin.database().ref('Users');
          ref2.once('value', function(snapshot2) {
            var users = snapshot2.val();
            var i = 0;
            var tokens = [];
            for (; i < uids.length; i++) {
              var uid = uids[i];
              var token = users[uid]['token'];
              tokens.push(token);
            }
            var noti = { notification:
              { title: "A seat has opened up in " + id,
              body: "Get to WesMaps to enroll!" },
              tokens: tokens,
            };

            admin.messaging().sendMulticast(noti)

            .then((response) => {
              return console.log("success!");
            })
            .catch((error) => {
            return console.log(error)
          });
        });
      });

    }
});

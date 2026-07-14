import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

admin.initializeApp();

/**
 * ─────────────────────────────────────────────────────────────
 * TRIGGER: Nouveau rechargement (topUp) créé
 * Path: users_v2/{uid}/wallet/{walletId}/topUps/{topUpId}
 * ─────────────────────────────────────────────────────────────
 * Envoie un push FCM au client concerné, même si l'app est
 * fermée ou en arrière-plan.
 */
export const onTopUpCreated = onDocumentCreated(
  "users_v2/{uid}/wallet/{walletId}/topUps/{topUpId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("Aucune donnée dans l'event topUp");
      return;
    }

    const topUp = snap.data();
    const uid = event.params.uid;
    const amount = topUp.amount as number;
    const newBalance = topUp.newBalance as number;

    logger.info(`Nouveau topUp pour ${uid}: +${amount} SPM`);

    // Récupérer le FCM token du client
    const userDoc = await admin
      .firestore()
      .collection("users_v2")
      .doc(uid)
      .get();

    if (!userDoc.exists) {
      logger.warn(`Utilisateur ${uid} introuvable`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken as string | undefined;

    if (!fcmToken) {
      logger.warn(`Pas de FCM token pour ${uid}`);
      return;
    }

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: "💰 Rechargement effectué !",
        body: `Vous avez reçu ${amount} SPM. Nouveau solde : ${newBalance} SPM.`,
      },
      android: {
        notification: {
          icon: "ic_notification",
          color: "#3D5AFE",
          channelId: "high_importance_channel",
        },
      },
      data: {
        type: "topup",
        amount: amount.toString(),
        newBalance: newBalance.toString(),
      },
    };

    try {
      const response = await admin.messaging().send(message);
      logger.info(`Push envoyé avec succès: ${response}`);

      // Sauvegarder aussi dans la collection notifications
      // pour l'historique dans l'app
      await admin
        .firestore()
        .collection("users_v2")
        .doc(uid)
        .collection("notifications")
        .add({
          title: "💰 Rechargement effectué !",
          body: `Vous avez reçu ${amount} SPM. Nouveau solde : ${newBalance} SPM.`,
          isRead: false,
          receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (error) {
      logger.error("Erreur envoi push FCM:", error);
    }
  }
);

/**
 * ─────────────────────────────────────────────────────────────
 * TRIGGER: Nouvelle réservation créée
 * Path: slotsReservations_v2/{bookingId}
 * ─────────────────────────────────────────────────────────────
 * Envoie un push FCM au client pour confirmer la réservation.
 */
export const onBookingCreated = onDocumentCreated(
  "slotsReservations_v2/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const booking = snap.data();
    const clientId = booking.clientId as string;
    const spotId = booking.spotId as string;
    const parkingId = booking.parkingId as string;

    logger.info(`Nouvelle réservation pour ${clientId}: Place ${spotId}`);

    const userDoc = await admin
      .firestore()
      .collection("users_v2")
      .doc(clientId)
      .get();

    if (!userDoc.exists) return;

    const fcmToken = userDoc.data()?.fcmToken as string | undefined;
    if (!fcmToken) {
      logger.warn(`Pas de FCM token pour ${clientId}`);
      return;
    }

    // Récupérer le nom du parking
    let parkingName = parkingId;
    try {
      const parkingDoc = await admin
        .firestore()
        .collection("locations_v2")
        .doc(parkingId)
        .get();
      if (parkingDoc.exists) {
        parkingName = parkingDoc.data()?.name ?? parkingId;
      }
    } catch (e) {
      logger.warn("Impossible de récupérer le nom du parking", e);
    }

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: "✅ Réservation confirmée !",
        body: `Place ${spotId} — ${parkingName}`,
      },
      android: {
        notification: {
          icon: "ic_notification",
          color: "#3D5AFE",
          channelId: "high_importance_channel",
        },
      },
      data: {
        type: "booking_confirmed",
        bookingId: event.params.bookingId,
        spotId: spotId,
      },
    };

    try {
      await admin.messaging().send(message);
      logger.info("Push réservation confirmée envoyé");
    } catch (error) {
      logger.error("Erreur envoi push réservation:", error);
    }
  }
);

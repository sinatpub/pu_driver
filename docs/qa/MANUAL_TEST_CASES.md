# PU Taxi Driver: manual test cases for a real device

Written 2026-10-07 for the `dev` branch, running against the real backend
(`taxi-api.simpledevelopertools.com`). 144 cases in 15 groups. A full pass takes
about half a day with two phones; groups F to I are the core and take about
90 minutes.

Screen texts below are the English ones. In Khmer the place is the same and the
words differ.

## 1. Before you start

### What you need

| Item | Detail |
|---|---|
| Driver phone | Android, real device, GPS and mobile data on. This is the phone under test. |
| Passenger phone | Second phone (or emulator) with the PU Taxi passenger app, signed in as a passenger. |
| Driver account | An approved driver. In a debug build the "Debug login" button signs in as the account in `dart_defines.json`. |
| Admin panel | Needed only for group E (approve, reject) and to top up a wallet. |
| Both phones near each other | The passenger must request a ride close to the driver, or no request arrives. |

### Build to test

Debug build, real data, on a connected phone:

```bash
fvm flutter run -d <device-id> --dart-define-from-file=dart_defines.json
```

Or install a debug APK:

```bash
fvm flutter build apk --debug --dart-define-from-file=dart_defines.json
```

- **Debug build:** has the "Debug login" button and prints each API call in the
  console.
- **Release build:** no "Debug login". You need a real phone number and the SMS
  code.
- **Invite feature (group K):** shows only when `dart_defines.json` has
  `"DEMO_INVITE": "true"`. Its figures are sample data.

### How to record a result

Mark each case **Pass**, **Fail** or **Blocked** in the last column. For a
fail, write a bug with the template in section 3.

There is no logout in the app. To sign in as another driver, clear the app's
data in Android settings, or reinstall.

### Known gaps today

These fail today and are already known. Do not report them again; do report if
they behave differently from what is written here.

| # | What you will see | Why |
|---|---|---|
| Gap 1 | No route line on the map. Time and distance to pickup are missing. The request has no fare estimate. | Google refuses the route request for the app's map key. |
| Gap 2 | A driver who is waiting for approval, or rejected, is not blocked. Going online fails with a message from the server. | The backend does not send the driver's status where the app reads it. |
| Gap 3 | Wallet rows show the word "payment" with no + or − sign. | The backend's row type has no name in the app yet. |
| Gap 4 | Ride fares are in dollars (`$0.50`); the wallet is in riel (`៛`). | The backend does not send a currency with a ride. |
| Gap 5 | Invite, rewards and transfer show sample data. A transfer moves no real money. | The backend has no routes for them yet. |
| Gap 6 | No logout button. | Product decision still open. |
| Gap 7 | No ride alert on a phone whose app Android has closed by itself (O-11, O-12). | The backend does not push a ride request yet; the app is ready for it. |

---

## 2. Test cases

### A. Install and first launch

| ID | Steps | Expected | Result |
|---|---|---|---|
| A-01 | Install the app. Open it. | Splash with the PU Taxi mark, then the login page. No crash. | |
| A-02 | On first open, watch for system dialogs. | Android asks for notifications, then for location. | |
| A-03 | Answer "Don't allow" to notifications. | The app continues to the login page. | |
| A-04 | Close the app fully. Open it again. | Opens on the login page again (not signed in yet). | |
| A-05 | On the login page, tap English, then ខ្មែរ. | All texts on the page change language at once. | |

### B. Sign in

| ID | Steps | Expected | Result |
|---|---|---|---|
| B-01 | Leave the phone number empty. Tap "Next". | Error under the field: "Please check your phone number". No OTP page. | |
| B-02 | Type 5 digits. Tap "Next". | Error: "Phone Number must be 8 digits up". | |
| B-03 | Type a registered driver number. Tap "Next". | "Next" shows a spinner, then the OTP page: "Enter the 4-digit code sent to" and the number. | |
| B-04 | On the OTP page, wait without typing. | A countdown runs. When it ends, "Resend CODE" can be tapped. | |
| B-05 | Tap "Resend CODE". | A new SMS arrives. The countdown starts again. | |
| B-06 | Type a wrong 4-digit code. | A dialog says the code is wrong. The boxes are cleared so you can type again. | |
| B-07 | Type the correct code from the SMS. | The home page opens with the map. | |
| B-08 | Debug build only: on the login page tap "Debug login". | The button spins, then the home page opens. No OTP page. | |
| B-09 | Debug build only: turn mobile data and Wi-Fi off. Tap "Debug login". | A dialog shows an error message. You stay on the login page. | |
| B-10 | Sign in, then close the app fully and open it again. | The home page opens directly. No login page. | |

### C. New driver sign-up

Use a phone number that is not registered.

| ID | Steps | Expected | Result |
|---|---|---|---|
| C-01 | Enter the new number, then the correct OTP. | "Driver registration" opens. | |
| C-02 | Tap "Submit for review" with every field empty. | Nothing is sent. "All fields are required." or the button stays off. | |
| C-03 | Tap "Vehicle type". | A list of vehicle types from the server opens (for example "Moto"). | |
| C-04 | Tap each of the 4 photo slots. Choose "Take a photo", then "Gallery" for another. | Camera or gallery opens. The chosen photo shows in the slot. | |
| C-05 | Tap the X on an attached photo. | The slot is empty again. | |
| C-06 | Fill every field and all 4 photos. Tap "Submit for review". | The request is sent. The app moves on (home, or a waiting page). No crash. | |
| C-07 | In the admin panel, find the new driver. | The driver is there with the name, plate and 4 photos you entered. | |

### D. Home and going online

| ID | Steps | Expected | Result |
|---|---|---|---|
| D-01 | Sign in as an approved driver. Allow location. Watch the card at the bottom of the map. | First "You're offline · Checking your account…" with a thin moving bar. Then, with no tap, "You're online · Receiving requests". The pill at the top right says "Online". | |
| D-02 | Look at the map. | Your vehicle marker is at your real position. | |
| D-03 | Walk or drive 100 m. | The marker follows. | |
| D-04 | Tap the "Online" pill. | It changes to "Offline". The card says "You're offline · Go online to receive requests". | |
| D-05 | While offline, ask the passenger phone to request a ride. | No request arrives on the driver phone. | |
| D-06 | Tap the "Offline" pill. | Back to "Online". | |
| D-07 | Go offline with the pill. Open another tab (Wallet), then come back to Home. | Still offline. The app does not turn you back on. | |
| D-08 | Go offline. Close the app fully. Open it again. | After the check, you are put online again without a tap. | |
| D-09 | In Android settings, turn the app's location permission off. Open the app. | The home shows "Location permission is off" and "Open settings". You are not put online. | |
| D-10 | Tap "Open settings". Allow location. Return to the app. | The map shows. You are put online. | |
| D-11 | Turn the phone's GPS off (location switch). Open the app. | A message that the location could not be found, or "Finding your location…". No crash. Not online. | |
| D-12 | Turn off mobile data and Wi-Fi while on the home page. | A banner at the top: "No internet — reconnecting…". | |
| D-13 | Turn the internet back on. | The banner goes away within a few seconds. | |
| D-14 | Open the app with no internet. | The card says "Couldn't check your account" with a "Please try again" button. No spinner. You are not online. | |
| D-15 | Turn the internet on. Tap "Please try again". | The check runs, then you are put online. | |

### E. Account approval

Needs the admin panel. See gap 2: today these may not block the driver.

| ID | Steps | Expected | Result |
|---|---|---|---|
| E-01 | Sign in as a driver who is still waiting for approval. | A full page under the top bar: clock icon, "Waiting Approval From Admin", three steps (Documents sent, Under review, Ready to drive), "Contact support", "Check again". The top bar and menu still work. | |
| E-02 | On that page tap "Contact support". | The phone's dialer opens with the support number. | |
| E-03 | Approve the driver in the admin panel. On the phone tap "Check again". | The page goes away. The home shows, and the driver is put online. No app restart needed. | |
| E-04 | Sign in as a rejected driver. | Same page with a red cross: "Application not approved". No steps list. | |
| E-05 | As a waiting driver, tap the "Offline" pill. | A short message names the reason. The driver stays offline. | |

### F. Ride request

The driver is online. The passenger requests a ride near the driver.

| ID | Steps | Expected | Result |
|---|---|---|---|
| F-01 | Driver app open on Home. Passenger requests a ride. | Within a few seconds the request page opens by itself, with a sound. It shows "New request", the passenger's name, the pickup address and a countdown "to decide". | |
| F-02 | Look at the map on the request page. | Your vehicle and the pickup point are both marked. (Route line: see gap 1.) | |
| F-03 | Do nothing until the countdown ends. | The request closes. You are back on Home, still online. | |
| F-04 | New request. Tap "Decline". | The request closes. Back on Home, still online. | |
| F-05 | Driver app in the background (press the phone's home button). Passenger requests a ride. | A notification "New Ride Requests" arrives with sound. | |
| F-06 | Tap that notification. | The app opens on the request page. | |
| F-07 | Lock the driver phone. Passenger requests a ride. | The notification shows on the lock screen with sound. | |
| F-08 | Close the driver app fully (swipe it away). Passenger requests a ride. | A notification still arrives. Tapping it opens the app. | |
| F-09 | Two driver phones online near the passenger. Passenger requests. Both tap "Accept". | One gets the trip. The other sees "Booking has already been accepted by another driver." | |
| F-10 | Passenger requests, then cancels before the driver answers. | On the driver phone a dialog says "Bookings canceled · Passengers canceled their reservations." | |

### G. A complete trip, no destination

The passenger requests a ride without choosing a destination.

| ID | Steps | Expected | Result |
|---|---|---|---|
| G-01 | On the request page tap "Accept". | Stage "Go to passenger". The bar shows step 2 of 4. Button "I've arrived". The passenger's name with a call button. On the passenger phone: the driver is found. | |
| G-02 | Tap the call button. | The dialer opens with the passenger's number. | |
| G-03 | Drive to the pickup. Tap "I've arrived". | Stage "At pickup". A waiting timer counts up. Button "Start ride". The passenger phone shows the driver has arrived. | |
| G-04 | Tap "Start ride". | Stage "On trip". A trip timer runs. "Fare so far ≈ $0.50" (the minimum fare). The passenger phone shows the trip has started. | |
| G-05 | Drive more than 1 km. Watch the distance and fare. | Distance goes up as you move. After 1 km the fare rises above the minimum, in dollars with two decimals (for example `≈ $0.56`). It is never `$0` or `៛0`. | |
| G-06 | Stop at a red light for one minute. | Distance does not grow while you stand still. The timer keeps running. | |
| G-07 | Tap the drop-off button once, quickly. | Nothing happens. The button says "Hold to drop off". | |
| G-08 | Press and hold the drop-off button. | The trip ends. The payment page opens. The passenger phone shows the trip has ended. | |
| G-09 | Read the payment page. | "Trip complete" or "Collect payment". One amount in dollars with two decimals, the distance, the time, and "Collect in cash" with "Take $x.xx in cash, then confirm." | |
| G-10 | Compare the amount with the passenger phone. | Both phones show the same amount. | |
| G-11 | Tap "Cash received". | Back on Home, online, ready for the next request. The passenger phone closes its payment page. | |
| G-12 | Right after, open History. | The trip is first in "Completed" with the same amount. | |

### H. A complete trip, with destination

The passenger chooses a destination before requesting.

| ID | Steps | Expected | Result |
|---|---|---|---|
| H-01 | Open the request. | It shows pickup and destination, trip distance and "Est. fare". (Distance and fare may be missing: gap 1.) | |
| H-02 | Accept, arrive, start the ride. | Same stages as group G. On trip, the destination is marked on the map. | |
| H-03 | Hold to drop off at the destination. | The payment page opens with the final amount in dollars. | |
| H-04 | Hold to drop off far before the destination. | The trip still ends. The amount is the server's, not the first estimate. | |

### I. Trip problems

| ID | Steps | Expected | Result |
|---|---|---|---|
| I-01 | Accept a request. Before arriving, tap "Cancel request". | A question: "Cancel request? The passenger is waiting. Cancel this request?" with "Yes, cancel" and "Stay". | |
| I-02 | Tap "Stay". | The trip continues. | |
| I-03 | Tap "Cancel request", then "Yes, cancel". | Back on Home. The passenger phone learns the driver cancelled. The trip is in History under "Cancelled". | |
| I-04 | Accept a request. On the passenger phone, cancel the ride. | The driver phone shows "Bookings canceled". After closing it you are on Home. | |
| I-05 | Start a ride and drive 1 km. Close the app fully. Open it again. | "Resuming your trip…", then the trip page at "On trip". The timer, distance and fare continue from where they were. They do not go back to `0 m` and `$0.50`. | |
| I-06 | Same as I-05, but drive 500 m while the app is closed, then open it. | After the next GPS update the distance also includes most of the stretch driven while closed. | |
| I-07 | At "At pickup", close the app fully. Open it again. | The trip page opens at "At pickup". The waiting timer continues; it does not restart at zero. | |
| I-08 | During a trip, turn the internet off for 30 seconds, then on. | The banner "No internet — reconnecting…" shows, then goes. The trip page is still there. | |
| I-09 | With the internet off, tap "I've arrived" (or "Start ride"). | An error message. The stage does not change. After the internet is back, the same button works. | |
| I-10 | During a trip, take a phone call for one minute, then return to the app. | The trip page is unchanged. The timer shows the true elapsed time. | |
| I-11 | During a trip, lock the phone for five minutes while driving. Unlock. | Distance driven includes the locked stretch, or most of it. Note the difference if large. | |
| I-12 | On the payment page, close the app fully before confirming. Open it again. | The app returns to the payment page for that trip. | |
| I-13 | On the payment page, turn the internet off. Tap "Cash received". | An error message. You stay on the page and can try again. | |

### J. History and wallet

| ID | Steps | Expected | Result |
|---|---|---|---|
| J-01 | Menu → History. | Two tabs: "Completed" and "Cancelled". Trips are grouped by day, newest first ("Today", "Yesterday", then dates). | |
| J-02 | Look at one completed trip. | Time, amount in dollars, pickup and drop-off, passenger name, distance and duration. | |
| J-03 | Tap a completed trip. | "Trip details": total price, payment method, distance, duration, route, and a card "Found something the passenger left?". | |
| J-04 | On a trip less than 24 hours old, tap "Call passenger". | The dialer opens. | |
| J-05 | Open "Cancelled". | Cancelled trips show with no amount. | |
| J-06 | As a new driver with no trips, open History. | "No completed trips yet" and "No cancelled trips". | |
| J-07 | Scroll to the end of a long history. | More trips load. No duplicates, no endless spinner. | |
| J-08 | Menu → Wallet. | "Balance" with an amount, and "Platform commission: N% of each trip". Below it, "History" with rows grouped by day. | |
| J-09 | Pull down on the wallet page. | It reloads. | |
| J-10 | Finish a cash trip, then open Wallet. | A new row for that trip. Note the amount and the sign. (Row name: see gap 3.) | |
| J-11 | Have the admin top up the driver. Open Wallet. | The balance grows by the top-up. A "Top up" row with + shows. | |
| J-12 | Open Wallet with no internet. | An error with "Please try again", not an endless loading page. | |

### K. Invite, rewards and transfer (sample data)

Only in a build with `DEMO_INVITE=true`. The figures restart each time the app
starts.

| ID | Steps | Expected | Result |
|---|---|---|---|
| K-01 | On Home, tap the round QR button above the status card. | A sheet "My QR" with a QR code, an invite code, "Copy code" and "Share invite link". | |
| K-02 | Tap "Copy code". Paste into any notes app. | "Code copied" shows. The pasted text is the code. | |
| K-03 | Tap "Share invite link". | The phone's share sheet opens with a text that contains the code and a link. | |
| K-04 | Scan the QR with another phone's camera. | It reads a link that ends with the invite code. | |
| K-05 | Menu → Wallet. | Under the balance, a card "Invite rewards" with a reward balance and "Transfer to balance". | |
| K-06 | Tap the card (not the button). | The rewards page with two tabs: "Rewards" and "People". | |
| K-07 | Rewards tab. | "Reward balance", "Total earned", "Transferred to balance", "From drivers", "From passengers", "How you earn" and a history. | |
| K-08 | People tab. Tap "Drivers", then "Passengers". | The list filters. Each person shows a name, the join date and what they earned you. | |
| K-09 | Tap "Transfer to balance". Leave the amount empty. | The confirm button cannot be used. | |
| K-10 | Type an amount larger than the reward balance. | "You have ៛… to transfer." The button cannot be used. | |
| K-11 | Type a valid amount, for example 1000. | The sheet shows "Balance after", "Rewards left" and "This cannot be moved back." | |
| K-12 | Confirm the transfer. | A message "៛1,000 moved to your balance". The reward balance is 1,000 lower. The wallet balance is 1,000 higher. Wallet history has a "Reward transfer" row with +. | |
| K-13 | Transfer the whole remaining reward balance. | Reward balance is ៛0. The card says "Nothing to transfer" and the button is gone. | |
| K-14 | Close the app fully and open it again. | The sample figures are back to the start (see gap 5). | |
| K-15 | New driver sign-up: type invite code `SOKHA88`. | "Invited by Sokha Vann". | |
| K-16 | Type a wrong code, for example `XXXX99`. Try to submit. | "Code not recognised. Check it, or clear it to continue." Submit is blocked until the code is fixed or cleared. | |

### L. Announcements, terms, contact, language

| ID | Steps | Expected | Result |
|---|---|---|---|
| L-01 | Tap the bell at the top of Home. | The announcements list, or "No announcements yet". | |
| L-02 | Create an announcement in the admin panel. Pull to refresh. | It shows in the list, marked unread. | |
| L-03 | Tap an announcement. | The detail page with title, date and text. Back returns to the list. | |
| L-04 | Menu → Term & Condition. | Five numbered terms, readable, nothing cut off. | |
| L-05 | Menu → Contact Us. Tap "Call us". | The dialer opens with the support number. | |
| L-06 | On Contact Us, tap "Email", then "Office · open in maps". | The mail app opens; then a maps app opens. | |
| L-07 | On Contact Us, read the bottom of the page. | "Version" with a number. | |
| L-08 | Menu → "Choose language" → ខ្មែរ. | The menu and every page change to Khmer at once. | |
| L-09 | In Khmer, open Home, Wallet, History, a trip page and the payment page. | No English left over, no text cut off, no text over other text. | |
| L-10 | Close the app fully and open it again. | Still Khmer. | |

### M. Network, session and updates

| ID | Steps | Expected | Result |
|---|---|---|---|
| M-01 | Use the app for ten minutes on slow mobile data (2G or 3G). | Pages load with a loading state, then content. No crash, no blank page. | |
| M-02 | Move between Wi-Fi and mobile data while online. | The driver stays online. A new request still arrives. | |
| M-03 | Sign in on a second phone with the same driver account, if the backend allows one session only. Use the first phone again. | The first phone returns to the login page by itself. Note what happens if it does not. | |
| M-04 | Leave the app in the background for one hour while online. Then have the passenger request a ride. | The request arrives (as a notification). | |
| M-05 | If the admin sets a newer required app version: open the app. | "Update required" with "Update now". The app cannot be used behind it. | |

### N. Device checks

| ID | Steps | Expected | Result |
|---|---|---|---|
| N-01 | Android settings → Display → Font size → largest. Open login, Home, a trip page, Wallet. | Text is larger. Note every place where text is cut or overlaps. | |
| N-02 | Use a small phone (width about 320 dp), in Khmer. | Same check as N-01. | |
| N-03 | Rotate the phone during a trip. | The page stays in portrait, or redraws without losing the trip. | |
| N-04 | Turn battery saver on. Drive a 2 km trip with the screen locked half the time. | The trip completes. Note the distance against the car's odometer or a maps app. | |
| N-05 | Drive a known distance, for example 3.0 km on a maps app, with no destination. | "x driven" is within about 10% of the real distance. Write both numbers. | |
| N-06 | Work for two hours with the app online. | Note the battery used. The phone does not get hot. | |
| N-07 | During a trip, open a maps app for navigation, then return. | The trip page is unchanged; distance kept counting. | |
| N-08 | Receive a request while music or a call is playing. | The request sound is still heard. | |

### O. Online with the screen off, and clearing the app (Android)

Added 2026-10-13 (DD-58). Use a real phone as well as an emulator: phone makers
differ in how hard they close apps. For O-06 to O-09, read the result in
`adb logcat -s OnlineService` or on the admin side.

| ID | Steps | Expected | Result |
|---|---|---|---|
| O-01 | Sign in and let the app go online. Pull down the notification shade. | A permanent notification: "You're online", "Receiving requests". It cannot be swiped away. It makes no sound. | |
| O-02 | Tap the pill to go offline. | The notification goes away. | |
| O-03 | Go online. Tap the notification from another app. | The driver app comes to the front. | |
| O-04 | Online. Lock the phone. Wait 5 minutes. Send a booking from the passenger app. | The request sound plays with the screen off. Unlocking shows the ride request. | |
| O-05 | Online. Press Home and open another app. Wait 5 minutes. Send a booking. | The request sound plays and a notification shows. Opening the app shows the ride request. | |
| O-06 | Online, no trip. Clear the app from the recent apps. | The "You're online" notification goes away within a few seconds. The log says "app cleared, offline call answered 201". The backend has the driver offline. | |
| O-07 | After O-06, send a booking from the passenger app. | This driver is not offered the ride. | |
| O-08 | After O-06, open the app again. | The app goes online by itself, and the notification is back. | |
| O-09 | Accept a ride, so a trip is running. Clear the app from the recent apps. | The notification goes away. No offline call in the log. Opening the app again returns to the trip. | |
| O-10 | Turn location permission off for the app in Android settings. Open the app and try to go online. | No crash. The log says the service was not started. | |
| O-11 | Online. In Android settings, "Force stop" the app, or let a phone maker's battery saver close it. Send a booking. | Known gap 7 today: no alert, and `adb logcat -s flutter` shows no "ride push" line. When the backend pushes ride requests, the line is there with `announced=true`, the request sound plays, and it stops when the request times out. | |
| O-12 | Change the language to English, then repeat O-11 once the backend pushes. | The alert is in English. | |

---

## 3. Bug report template

Copy this for each failed case.

```text
Case ID:
Title:          one line, what is wrong
Build:          debug or release, date, commit (git log -1 --format=%h)
Device:         model, Android version
Account:        driver phone number
Language:       English or Khmer
Network:        Wi-Fi, 4G, 3G, offline

Steps:
1.
2.
3.

Expected:
Actual:

Time it happened:   (helps find it in the server log)
Screenshot or video:
Console log:        for an API error, the response body only — not the curl
                    line, it holds the sign-in token
```

## 4. Sign-off

| Group | Cases | Pass | Fail | Blocked |
|---|---|---|---|---|
| A. Install and first launch | 5 | | | |
| B. Sign in | 10 | | | |
| C. New driver sign-up | 7 | | | |
| D. Home and going online | 15 | | | |
| E. Account approval | 5 | | | |
| F. Ride request | 10 | | | |
| G. Trip, no destination | 12 | | | |
| H. Trip, with destination | 4 | | | |
| I. Trip problems | 13 | | | |
| J. History and wallet | 12 | | | |
| K. Invite, rewards, transfer | 16 | | | |
| L. Announcements, terms, contact, language | 10 | | | |
| M. Network, session, updates | 5 | | | |
| N. Device checks | 8 | | | |
| O. Online with the screen off, clearing the app | 12 | | | |
| **Total** | **144** | | | |

Tested by: ____________  Date: ____________  Build: ____________

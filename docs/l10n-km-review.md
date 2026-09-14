# Khmer copy review — UX redesign

For a native Khmer reviewer. Every Khmer string the redesign added or changed is listed here with its English source. This review is what P2 (copy and localization sweep) is waiting on — see `IMPLEMENTATION_PROGRESS.md`.

How to use it: correct the Khmer column in `assets/translations/km.json` (same key), then tick the row. **Never change** `ACCEPT`, `ARRIVE` or `START_RIDE` — they double as notification titles.

Generated 2026-09-14 from `git diff HEAD` of the locale files.

## 1. Developer drafts — review every one (39)

No native source. Highest risk.

| ✓ | Key | English | Khmer |
|---|---|---|---|
| ☐ | `ADDRESS_NOT_FOUND` | Address not found | រកមិនឃើញអាសយដ្ឋាន |
| ☐ | `APPROVAL_CHECKING` | Checking your account… | កំពុងពិនិត្យគណនីរបស់អ្នក… |
| ☐ | `APPROVAL_CHECKING_DES` | We're confirming your approval status. | យើងកំពុងពិនិត្យស្ថានភាពគណនីរបស់អ្នក។ |
| ☐ | `APPROVAL_REJECTED_DESC` | Please re-submit your documents or contact support. | សូមដាក់ស្នើម្តងទៀត ឬទាក់ទងជំនួយ។ |
| ☐ | `CANCEL_REQUEST` | Cancel request | បោះបង់ភ្ញៀវ |
| ☐ | `CONNECTION_TIMED_OUT` | Connection timed out. Please try again later. | ការតភ្ជាប់យូរពេក។ សូមព្យាយាមម្ដងទៀតនៅពេលក្រោយ។ |
| ☐ | `CONTACT_BLURB` | Feel free to reach out to us if you have any questions, feedback, or issues. | សូមទាក់ទងមកយើង ប្រសិនបើអ្នកមានសំណួរ មតិយោបល់ ឬបញ្ហា។ |
| ☐ | `COPYRIGHT` | © 2025 TAARRAA. All rights reserved. | © 2025 TAARRAA. រក្សាសិទ្ធិគ្រប់យ៉ាង។ |
| ☐ | `EMPTY_ANNOUNCEMENTS` | No announcements yet | មិនទាន់មានសេចក្ដីជូនដំណឹង |
| ☐ | `EMPTY_CANCELLED` | No cancelled trips | មិនមានដំណើរដែលបានបោះបង់ |
| ☐ | `EMPTY_COMPLETED` | No completed trips yet | មិនទាន់មានដំណើរដែលបានបញ្ចប់ |
| ☐ | `FAILED_TO_LOAD_DATA` | Couldn't load data | មិនអាចផ្ទុកទិន្នន័យបានទេ |
| ☐ | `FULL_NAME_HINT` | Enter your full name | បញ្ចូលឈ្មោះពេញ |
| ☐ | `LOCATION_DENIED` | Location permission is off | ការអនុញ្ញាតទីតាំងត្រូវបានបិទ |
| ☐ | `LOCATION_DENIED_DES` | Taarraa needs your location to receive ride requests. | តារាត្រូវការទីតាំងរបស់អ្នក ដើម្បីទទួលការកក់។ |
| ☐ | `LOCATION_FAILED` | Couldn't get your location | មិនអាចទាញយកទីតាំងបានទេ |
| ☐ | `LOCATION_FINDING` | Finding your location… | កំពុងស្វែងរកទីតាំងរបស់អ្នក… |
| ☐ | `NO_INTERNET_RECONNECTING` | No internet — reconnecting… | គ្មានអីនធឺណិត — កំពុងភ្ជាប់… |
| ☐ | `OK` | OK | OK |
| ☐ | `OPEN_SETTINGS` | Open settings | បើកការកំណត់ |
| ☐ | `OTP_INCORRECT` | Please make sure you entered the correct code. | សូមប្រាកដថាអ្នកបានបញ្ចូលលេខកូដត្រឹមត្រូវ។ |
| ☐ | `PHOTO_CAMERA` | Take a photo | ថតរូប |
| ☐ | `PHOTO_GALLERY` | Gallery | កន្លែងផ្ទុករូបថត |
| ☐ | `REGISTER_FIELDS_REQUIRED` | All fields are required. | ត្រូវបំពេញព័ត៌មានទាំងអស់។ |
| ☐ | `RESUMING_TRIP` | Resuming your trip… | កំពុងបន្តដំណើររបស់អ្នក… |
| ☐ | `TOTAL_TO_COLLECT` | Total to collect | ប្រាក់សរុបដែលត្រូវទទួល |
| ☐ | `TRIP_DETAILS` | Trip details | ព័ត៌មានលម្អិតនៃដំណើរ |
| ☐ | `TRY_AGAIN` | Try again | ព្យាយាមម្ដងទៀត |
| ☐ | `UNREAD` | Unread | មិនទាន់អាន |
| ☐ | `UPDATE_NOW` | Update now | ធ្វើបច្ចុប្បន្នភាពឥឡូវ |
| ☐ | `UPDATE_REQUIRED` | Update required | ត្រូវការធ្វើបច្ចុប្បន្នភាព |
| ☐ | `VEHICLE_ALPHARD_VIP` | Alphard VIP | ឡាន VIP |
| ☐ | `VEHICLE_CLASSIC_CAR` | Classic Car | ឡានតូច |
| ☐ | `VEHICLE_MINI_VAN` | Mini Van | ឡាន Van |
| ☐ | `VEHICLE_RICKSHAW` | Rickshaw | រ៉ឺម៉ក |
| ☐ | `VEHICLE_SUV` | SUV | ឡាន SUV |
| ☐ | `VEHICLE_TYPE_HINT` | Select vehicle type | ជ្រើសរើសប្រភេទយានយន្ដ |
| ☐ | `YOU_ARE_OFFLINE` | You're offline | អ្នកបានបិទទទួល |
| ☐ | `YOU_ARE_ONLINE` | You're online | អ្នកកំពុងបើកទទួល |

## 2. Terms & Conditions — needs a legal translation (5)

The Khmer file holds the **English** legal text on purpose: a draft of legal terms is not shipped. Supply a reviewed translation.

| ✓ | Key | English | Khmer |
|---|---|---|---|
| ☐ | `TERM_1` | All payments are made directly to the driver and are accepted in cash or with QR code. | All payments are made directly to the driver and are accepted in cash or with QR code. |
| ☐ | `TERM_2` | The company and its member drivers cannot be held responsible for any actual or consequential financial or professional loss due to the late or non-arrival of any rickshaw or cab. | The company and its member drivers cannot be held responsible for any actual or consequential financial or professional loss due to the late or non-arrival of any rickshaw or cab. |
| ☐ | `TERM_3` | The company cannot be held responsible for losses consequential from missed connections due to adverse weather or any other events. | The company cannot be held responsible for losses consequential from missed connections due to adverse weather or any other events. |
| ☐ | `TERM_4` | The company and its member drivers reserve the right to refuse to carry passengers who are deeply under the influence of alcohol or drugs. | The company and its member drivers reserve the right to refuse to carry passengers who are deeply under the influence of alcohol or drugs. |
| ☐ | `TERM_5` | All bookings accepted by the company will be bound by these terms and conditions. | All bookings accepted by the company will be bound by these terms and conditions. |

## 3. From the prototype dictionary (41)

Written for the prototype (`taarraa-driver-prototype.html`); confirm they read right in the app's context.

| ✓ | Key | English | Khmer |
|---|---|---|---|
| ☐ | `ACTION_ARRIVED` | I've arrived | ដល់ហើយ |
| ☐ | `ACTION_DROP_OFF` | Drop off | ដាក់ចុះ |
| ☐ | `ACTION_START_RIDE` | Start ride | ចាប់ផ្ដើម |
| ☐ | `ANNOUNCEMENTS` | Announcements | សេចក្ដីជូនដំណឹង |
| ☐ | `APPROVAL_REJECTED_TITLE` | Application not approved | ពាក្យត្រូវបានបដិសេធ |
| ☐ | `CANCEL_REQUEST_MSG` | The passenger is waiting. Cancel this request? | ភ្ញៀវកំពុងរង់ចាំ។ បោះបង់? |
| ☐ | `CANCEL_REQUEST_TITLE` | Cancel request? | បោះបង់ភ្ញៀវ? |
| ☐ | `COLLECT_HINT` | Collect cash from the passenger, then confirm below. | ប្រមូលសាច់ប្រាក់ពីភ្ញៀវ រួចបញ្ជាក់ខាងក្រោម។ |
| ☐ | `COLLECT_PAYMENT_TITLE` | Collect payment | ប្រមូលប្រាក់ |
| ☐ | `CONTACT_SUPPORT` | Contact support | ទាក់ទងជំនួយ |
| ☐ | `DESTINATION` | Destination | គោលដៅ |
| ☐ | `DOCUMENTS` | Documents (4 photos) | ឯកសារ (រូប 4) |
| ☐ | `DOC_DRIVER_LICENSE` | Driver license | បណ្ណបើកបរ |
| ☐ | `DOC_ID_CARD` | ID card | អត្តសញ្ញាណប័ណ្ណ |
| ☐ | `DOC_PROFILE_PHOTO` | Profile photo | រូបថតផ្ទាល់ |
| ☐ | `DOC_VEHICLE_PHOTO` | Vehicle photo | រូបថតយាន |
| ☐ | `EST_FARE` | Est. fare | ថ្លៃប៉ាន់ស្មាន |
| ☐ | `EST_NOTE` | ≈ estimated — final fare is confirmed after drop-off | ≈ ប៉ាន់ស្មាន — ម៉ាស៊ីនមេបញ្ជាក់ថ្លៃចុងក្រោយ |
| ☐ | `FULL_NAME` | Full name | ឈ្មោះពេញ |
| ☐ | `OFFLINE_SUB` | Go online to receive requests | បើកដើម្បីទទួលភ្ញៀវ |
| ☐ | `ONLINE_SUB` | Receiving requests | កំពុងទទួលភ្ញៀវ |
| ☐ | `OTP_SENT_TO` | Enter the 4-digit code sent to | បញ្ចូលលេខកូដ 4 ខ្ទង់ដែលផ្ញើទៅ |
| ☐ | `PICKUP` | Pickup | ចំណុចឡើង |
| ☐ | `PLATE_NUMBER` | Plate | ស្លាកលេខ |
| ☐ | `REGISTER_DESC` | Vehicle + documents for admin review | យានជំនិះ + ឯកសារសម្រាប់ពិនិត្យ |
| ☐ | `REGISTER_SUBMIT` | Submit for review | ដាក់ស្នើពិនិត្យ |
| ☐ | `REGISTER_TITLE` | Driver registration | ចុះឈ្មោះអ្នកបើកបរ |
| ☐ | `STAGE_AT_PICKUP` | At pickup | ដល់កន្លែងទទួល |
| ☐ | `STAGE_GO_TO_PICKUP` | Go to passenger | ទៅទទួលភ្ញៀវ |
| ☐ | `STAGE_NEW_REQUEST` | New request | មានភ្ញៀវថ្មី |
| ☐ | `STAGE_ON_TRIP` | On trip | កំពុងដឹកភ្ញៀវ |
| ☐ | `STAY` | Stay | នៅ |
| ☐ | `TIMELINE_ACCEPT` | Accept | ទទួល |
| ☐ | `TIMELINE_ARRIVE` | Arrive | ដល់ |
| ☐ | `TIMELINE_DROP` | Drop | ចុះ |
| ☐ | `TIMELINE_START` | Start | ចាប់ |
| ☐ | `TO_DECIDE` | to decide | ដើម្បីសម្រេច |
| ☐ | `VEHICLE_COLOR` | Color | ពណ៌ |
| ☐ | `VEHICLE_COLOR_HINT` | e.g. Yellow | ឧ. លឿង |
| ☐ | `VEHICLE_TYPE` | Vehicle type | ប្រភេទយាន |
| ☐ | `YES_CANCEL` | Yes, cancel | បាទ/ចាស៎ បោះបង់ |

## 4. Reused from existing app Khmer (1)

Existing Khmer strings reused under new keys — a quick check that the reuse fits.

| ✓ | Key | English | Khmer |
|---|---|---|---|
| ☐ | `MOBILE_NUMBER` | Mobile Number | លេខទូរសព្ទ |

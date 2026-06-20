# Security Headers — peteksapp.com
**תאריך:** יוני 2026  
**ממצא מקורי:** סריקת Nikto — 5 Security Headers חסרים  

---

## מה שונה ולמה

### הבעיה
GitHub Pages לא מאפשר הגדרת HTTP headers מותאמים אישית — הם נשלחים ישירות מהשרתים של GitHub ואי אפשר לשנותם.

### הפתרון שיושם — שתי שכבות

| Header | Meta Tag (עכשיו) | Cloudflare Worker (נדרש) |
|--------|-----------------|--------------------------|
| Content-Security-Policy | ✅ יושם | ✅ כלול ב-Worker |
| Referrer-Policy | ✅ יושם | ✅ כלול ב-Worker |
| Strict-Transport-Security | ❌ לא ניתן כ-meta | ✅ כלול ב-Worker |
| X-Content-Type-Options | ❌ לא ניתן כ-meta | ✅ כלול ב-Worker |
| Permissions-Policy | ❌ לא ניתן כ-meta | ✅ כלול ב-Worker |

> **למה HSTS ו-X-Content-Type-Options לא עובדים כ-meta?**  
> הדפדפן מעבד אותם רק כשהם מגיעים ב-HTTP response headers מהשרת — לפני שה-HTML בכלל נפרס.  
> meta tags מעובדים *אחרי* שה-HTML נטען, וזה מאוחר מדי עבור headers אלו.

---

## הסבר על כל Header

### 1. `Strict-Transport-Security` (HSTS)
```
max-age=31536000; includeSubDomains; preload
```
**מה עושה:** מורה לדפדפן לתקשר רק דרך HTTPS למשך שנה. מונע התקפות SSL-stripping ו-downgrade.  
**למה חשוב:** בלעדיו, תוקף ב-network יכול לנתב מחדש בקשות HTTP לגרסה לא מוצפנת.

### 2. `X-Content-Type-Options`
```
nosniff
```
**מה עושה:** מונע מהדפדפן "לנחש" את סוג הקובץ (MIME sniffing).  
**למה חשוב:** בלעדיו, קובץ תמונה שמכיל HTML זדוני עלול להתבצע כ-HTML.

### 3. `Referrer-Policy`
```
strict-origin-when-cross-origin
```
**מה עושה:** שולח את הדומיין בלבד (לא הנתיב המלא) כשגולש עובר לאתר אחר.  
**למה חשוב:** מונע דליפת URLs פנימיים לאתרים חיצוניים.

### 4. `Permissions-Policy`
```
camera=(), microphone=(), geolocation=(), interest-cohort=()
```
**מה עושה:** מבטל גישה ל-APIs של מצלמה, מיקרופון, מיקום ו-FLoC (Google tracking).  
**למה חשוב:** אתר סטטי שלא צריך שום API — עדיף לבטל הכל מפורשות.

### 5. `Content-Security-Policy` (CSP)
```
default-src 'self';
style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
font-src https://fonts.gstatic.com;
img-src 'self' https://tomercio.github.io data:;
script-src 'none';
object-src 'none';
frame-src 'none';
base-uri 'self';
form-action 'self';
```
**מה עושה:** מגדיר בדיוק אילו מקורות מותרים לטעינה.  
**למה חשוב:** מונע XSS — גם אם תוקף מצליח להזריק קוד, הדפדפן יחסום את ביצועו.  
**למה `unsafe-inline` ב-styles?** כי ה-HTML מכיל `<style>` blocks גדולים ו-style attributes inline — בלי זה האתר נשבר. ניתן לשפר עם hash בעתיד.

---

## הוראות הפעלת Cloudflare Worker

### דרישות מוקדמות
- חשבון Cloudflare חינמי (cloudflare.com)
- הדומיין `peteksapp.com` מנוהל דרך Cloudflare (DNS)

### שלבים

1. **כנס ל-Cloudflare Dashboard** → בחר את `peteksapp.com`
2. **Workers & Pages** → **Create Worker**
3. **מחק את הקוד הדיפולטי** והדבק את תוכן `cloudflare-worker.js`
4. לחץ **Deploy**
5. עבור ל-**Workers & Pages** → בחר את ה-Worker שיצרת
6. **Settings → Triggers → Add Route**
7. הכנס: `peteksapp.com/*` ובחר את הדומיין
8. הוסף גם: `www.peteksapp.com/*`
9. לחץ **Save**

---

## בדיקה אחרי יישום

### curl
```bash
curl -I https://peteksapp.com
```
תוצאה מצופה:
```
strict-transport-security: max-age=31536000; includeSubDomains; preload
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
permissions-policy: camera=(), microphone=(), geolocation=(), interest-cohort=()
content-security-policy: default-src 'self'; style-src ...
```

### דפדפן
1. פתח `https://peteksapp.com`
2. פתח DevTools → **Network** → לחץ על הבקשה הראשית (`peteksapp.com`)
3. עבור ל-**Headers** → **Response Headers**
4. חפש את ה-5 headers למעלה

### כלי אונליין
- [securityheaders.com](https://securityheaders.com/?q=peteksapp.com) — דירוג A-F
- [observatory.mozilla.org](https://observatory.mozilla.org/analyze/peteksapp.com) — בדיקה מקיפה

---

## קבצים שעודכנו

| קובץ | שינוי |
|------|-------|
| `docs/index.html` | הוספת CSP + Referrer-Policy כ-meta tags |
| `docs/privacy.html` | הוספת CSP + Referrer-Policy כ-meta tags |
| `docs/terms.html` | הוספת CSP + Referrer-Policy כ-meta tags |
| `docs/cloudflare-worker.js` | Worker מוכן לפריסה עם כל 5 ה-headers |

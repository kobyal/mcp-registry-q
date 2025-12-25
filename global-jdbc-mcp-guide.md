# מדריך MCP Global-JDBC

## מה זה MCP Global-JDBC?

MCP Global-JDBC הוא שרת Model Context Protocol המאפשר חיבור ועבודה עם בסיסי נתונים דרך JDBC. השרת מבוסס על Quarkus ומספק ממשק אחיד לעבודה עם מגוון בסיסי נתונים.

## הגדרת השרת

### דרישות מקדימות
- Java 21 או גרסה חדשה יותר מותקנת במערכת
- קובץ JAR של השרת: `MCPServer-1.0.0-runner.jar`
- דרייברי JDBC עבור בסיסי הנתונים הרלוונטיים

### מציאת נתיב Java
למציאת נתיב Java 21 במערכת:
```cmd
# Windows
where java
# או
java -version

# דוגמאות נתיבים נפוצים:
# C:\Program Files\Java\jdk-21\bin\java.exe
# C:\Program Files\Eclipse Adoptium\jdk-21.0.x-hotspot\bin\java.exe
# C:\dev\jdk-21\bin\java.exe
# C:\dev\proxyWrapper\jdk-21.0.5\bin\java.exe
```

### שגיאות נפוצות בנתיב Java
⚠️ **שים לב**: נתיב Java חייב להיות מדויק!
- ❌ שגוי: `C:\dev\proxyWrapper\jdk-21.0.5\bin\bin\java.exe` (bin כפול)
- ✅ נכון: `C:\dev\proxyWrapper\jdk-21.0.5\bin\java.exe`

### הגדרה בקובץ default.json

```json
{
  "mcpServers": {
    "global-jdbc": {
      "command": "[PATH_TO_JAVA21]\\bin\\java.exe",
      "args": [
        "-Xms512m",
        "-Xmx2g", 
        "-XX:+UseG1GC",
        "-XX:MaxGCPauseMillis=200",
        "-Dfile.encoding=UTF-8",
        "-Dsun.stdout.encoding=UTF-8",
        "-Dsun.stderr.encoding=UTF-8",
        "-cp",
        "[PATH_TO_MCP_JAR]\\MCPServer-1.0.0-runner.jar;[JDBC_DRIVERS_PATH]",
        "io.quarkus.runner.GeneratedMain"
      ],
      "env": {
        "jdbc.url": "[JDBC_CONNECTION_STRING_WITH_SSL_FIX]",
        "jdbc.user": "[USERNAME]",
        "jdbc.password": "[PASSWORD]"
      },
      "timeout": 60000,
      "disabled": false
    }
  },
  "tools": [
    "@global-jdbc"
  ],
  "allowedTools": [
    "@global-jdbc"
  ]
}
```

### דוגמה מעובדת (SQL Server)
```json
{
  "mcpServers": {
    "global-jdbc": {
      "command": "C:\\dev\\proxyWrapper\\jdk-21.0.5\\bin\\java.exe",
      "args": [
        "-Xms512m",
        "-Xmx2g", 
        "-XX:+UseG1GC",
        "-XX:MaxGCPauseMillis=200",
        "-Dfile.encoding=UTF-8",
        "-Dsun.stdout.encoding=UTF-8",
        "-Dsun.stderr.encoding=UTF-8",
        "-cp",
        "C:\\dev\\mcp\\mcpsql-guide\\MCPServer-1.0.0-runner.jar;C:\\dev\\mcp\\mcpsql-guide\\mssql-jdbc\\12.4.2.jre11\\mssql-jdbc-12.4.2.jre11.jar",
        "io.quarkus.runner.GeneratedMain"
      ],
      "env": {
        "jdbc.url": "jdbc:sqlserver://SQLSERVER:1433;database=test;trustServerCertificate=true;encrypt=false",
        "jdbc.user": "test",
        "jdbc.password": "test"
      },
      "timeout": 60000,
      "disabled": false
    }
  }
}
```

### פרמטרי JVM
- **-Xms512m**: זיכרון התחלתי
- **-Xmx2g**: זיכרון מקסימלי
- **-XX:+UseG1GC**: שימוש ב-G1 Garbage Collector
- **-XX:MaxGCPauseMillis=200**: הגבלת זמן השהיית GC
- **-Dfile.encoding=UTF-8**: קידוד קבצים UTF-8

### משתני סביבה נדרשים
- **jdbc.url**: כתובת חיבור לבסיס הנתונים
- **jdbc.user**: שם משתמש
- **jdbc.password**: סיסמה

### דוגמאות JDBC URLs
```
# DB2
jdbc:db2://[HOST]:[PORT]/[DATABASE]:charSet=UTF-8;

# SQL Server (עם פתרון בעיות SSL)
jdbc:sqlserver://[HOST]:[PORT];database=[DATABASE];trustServerCertificate=true;encrypt=false;

# Oracle
jdbc:oracle:thin:@[HOST]:[PORT]:[SID]

# MySQL
jdbc:mysql://[HOST]:[PORT]/[DATABASE]?useSSL=false

# PostgreSQL
jdbc:postgresql://[HOST]:[PORT]/[DATABASE]
```

## הגדרה בתוסף Amazon Q ב-IDE

### שלב 1: גישה לפאנל MCP Servers

![MCP Servers Panel](mcp00.PNG)

כפי שניתן לראות בתמונה למעלה:
1. פתח את Amazon Q ב-IDE
2. בחר בטאב "CHAT" בפאנל Amazon Q
3. תראה את הסעיף "MCP Servers" עם הכותרת "Add MCP servers to extend Q's capabilities"
4. ברשימה תראה שרתים קיימים:
   - **Active**: שרתים פעילים (עם סימן ירוק ✓)
   - **Disabled**: שרתים מושבתים (עם סימן כחול)

### שלב 2: הוספת שרת חדש
1. לחץ על הכפתור "+" בחלק העליון של פאנל MCP Servers
2. יפתח חלון "Add MCP Server" כמו בתמונה השנייה:

![Add MCP Server Dialog](mcp0.PNG)

### שלב 3: מילוי פרטי השרת
בחלון "Add MCP Server" מלא את השדות הבאים:

**Scope (היקף)**:
- בחר "Global - Used globally" (מומלץ)
- או "This workspace - Only used in this workspace"

**Name (שם)**:
- הזן: `global-jdbc`

**Transport (תחבורה)**:
- השאר את הברירת מחדל: `stdio`

**Command (פקודה)**:
- הזן את נתיב Java: `[PATH_TO_JAVA21]\bin\java.exe`
- דוגמה: `C:\Program Files\Java\jdk-21\bin\java.exe`

**Arguments (ארגומנטים)**:
לחץ על "Add" להוספת כל ארגומנט בנפרד:
- `-Xms512m`
- `-Xmx2g`
- `-XX:+UseG1GC`
- `-XX:MaxGCPauseMillis=200`
- `-Dfile.encoding=UTF-8`
- `-Dsun.stdout.encoding=UTF-8`
- `-Dsun.stderr.encoding=UTF-8`
- `-cp`
- `[PATH_TO_MCP_JAR]\MCPServer-1.0.0-runner.jar;[JDBC_DRIVERS_PATH]`
- `io.quarkus.runner.GeneratedMain`

**Environment variables (משתני סביבה)**:
לחץ על "Add" להוספת כל משתנה:
- **Name**: `jdbc.url`, **Value**: `[JDBC_CONNECTION_STRING]`
- **Name**: `jdbc.user`, **Value**: `[YOUR_USERNAME]`
- **Name**: `jdbc.password`, **Value**: `[YOUR_PASSWORD]`

**Timeout (זמן קצוב)**:
- השאר את הברירת מחדל: `60` (שניות)

### דוגמה מהתמונות

![Edit MCP Server Example](mcp1.PNG)

בתמונה למעלה ניתן לראות דוגמה של הגדרה .

### שלב 4: שמירה והפעלה
1. לחץ על הכפתור הכחול "Save" בתחתית החלון
2. השרת יתווסף לרשימת השרתים הפעילים
3. תראה אותו ברשימה עם סימן ירוק ✓ אם ההגדרה נכונה
4. אם יש בעיה, יופיע סימן אדום ❌ עם אפשרות "Fix Configuration"

### שלב 5: אימות השרת
לאחר השמירה, השרת אמור להופיע ברשימת ה-Active servers:
- **global-jdbc** עם סימן ירוק ✓
- מספר הכלים הזמינים (למשל: 14 כלים)
- חץ > לפרטים נוספים

### שלב 6: בדיקת פעילות השרת

![Server Functions](mcp2.PNG)

1. פתח צ'אט חדש ב-Amazon Q
2. נסה להריץ פקודה פשוטה:
   ```
   הצג לי את הסכמות בבסיס הנתונים
   ```
3. אם השרת עובד, תקבל תשובה עם רשימת הסכמות
4. אם יש בעיה, בדוק את הלוגים או חזור להגדרות

### ניהול שרתים קיימים
מהתמונה הראשונה ניתן לראות:
- **שרתים פעילים** (Active): מסומנים בירוק עם מספר הכלים
- **שרתים מושבתים** (Disabled): מסומנים בכחול עם אפשרות Enable
- **שרתים עם בעיות**: מסומנים באדום עם "Fix Configuration"
- **פעולות זמינות**: Enable, Delete, עריכה

### פתרון בעיות בהגדרה
אם השרת מופיע עם סימן אדום:
1. לחץ על "Fix Configuration"
2. בדוק את נתיב Java
3. וודא שקובץ ה-JAR קיים
4. בדוק את פרמטרי החיבור לבסיס הנתונים
5. שמור שוב את ההגדרות

## התקנה ותצורה מתקדמת

### שלב 1: הכנת הסביבה
```bash
# יצירת תיקיית עבודה
mkdir [YOUR_MCP_DIRECTORY]

# העתקת קובץ ה-JAR
copy MCPServer-1.0.0-runner.jar [YOUR_MCP_DIRECTORY]\

# דוגמאות נתיבים נפוצים:
# C:\dev\mcp\jdbc-server\
# C:\tools\mcp\jdbc\
# C:\Program Files\MCP\jdbc-server\
```

### שלב 2: הורדת דרייברי JDBC
הורד את הדרייברים הרלוונטיים:
- **DB2**: db2jcc.jar, db2jcc4.jar
- **SQL Server**: sqljdbc.jar, sqljdbc4.jar
- **Oracle**: ojdbc.jar
- **MySQL**: mysql-connector-java.jar

### שלב 3: עדכון ה-classpath
הוסף את כל הדרייברים ל-classpath בהגדרת ה-args:
```
[PATH_TO_MCP_JAR]\MCPServer-1.0.0-runner.jar;[DRIVER1];[DRIVER2];[DRIVER3]

# דוגמה:
C:\tools\mcp\MCPServer-1.0.0-runner.jar;C:\jdbc\db2jcc.jar;C:\jdbc\sqljdbc.jar
```

### שלב 4: הפעלת השרת
השרת יופעל אוטומטית על ידי Amazon Q כאשר נדרש.

## פעולות זמינות

### 1. שאילתות בסיסיות
- **jdbc_execute_query**: הרצת שאילתת SQL והחזרת תוצאות בפורמט JSON
- **jdbc_execute_query_md**: הרצת שאילתה והחזרת תוצאות בפורמט Markdown
- **jdbc_query_database**: הרצת שאילתה כללית

### 2. חקירת מבנה בסיס הנתונים
- **jdbc_get_schemas**: קבלת רשימת סכמות
- **jdbc_get_tables**: קבלת רשימת טבלאות בסכמה
- **jdbc_describe_table**: תיאור מבנה טבלה ספציפית
- **jdbc_filter_table_names**: חיפוש טבלאות לפי שם

### 3. תמיכה ב-SPARQL (עבור RDF)
- **jdbc_sparql_list_entity_types**: רשימת סוגי ישויות
- **jdbc_sparql_list_ontologies**: רשימת אונטולוגיות
- **jdbc_spasql_query**: הרצת שאילתות SPASQL

### 4. כלי עזר
- **jdbc_sparql_func**: פונקציות SPARQL מתקדמות
- **jdbc_virtuoso_support_ai**: תמיכה ב-Virtuoso AI

## דוגמאות שימוש

### חיבור לבסיס נתונים
```sql
-- בדיקת חיבור
SELECT CURRENT TIMESTAMP FROM SYSIBM.SYSDUMMY1;
```

### קבלת רשימת טבלאות
```javascript
// שימוש בפונקציה jdbc_get_tables
{
  "schema": "MYSCHEMA"
}
```

### תיאור טבלה
```javascript
// שימוש בפונקציה jdbc_describe_table  
{
  "table": "CUSTOMERS",
  "schema": "MYSCHEMA"
}
```

## פתרון בעיות נפוצות

### בעיית חיבור SSL (SQL Server)
**שגיאה**: `"encrypt" property is set to "true" and "trustServerCertificate" property is set to "false"`

**פתרון**: הוסף לכתובת החיבור:
```
jdbc:sqlserver://[HOST]:[PORT];database=[DATABASE];trustServerCertificate=true;encrypt=false;
```

### בעיית נתיב Java
**שגיאה**: `The system cannot find the file specified`

**פתרון**: בדוק שהנתיב נכון ללא `\bin` כפול:
```cmd
# בדיקת קיום הקובץ
dir "C:\dev\proxyWrapper\jdk-21.0.5\bin\java.exe"
```

### בעיית חיבור כללית
- בדוק את פרמטרי החיבור ב-jdbc.url
- וודא שהדרייבר הנכון נמצא ב-classpath
- בדוק חיבור רשת לשרת בסיס הנתונים

### בעיות זיכרון
- הגדל את פרמטר -Xmx אם נדרש
- בדוק שימוש בזיכרון עם כלי ניטור

### בעיות קידוד
- וודא שהגדרת UTF-8 בכל המקומות הרלוונטיים
- בדוק הגדרות קידוד בבסיס הנתונים

## הגדרות מתקדמות

### אופטימיזציה לביצועים
```json
"args": [
  "-Xms1g",
  "-Xmx4g",
  "-XX:+UseG1GC",
  "-XX:MaxGCPauseMillis=100",
  "-XX:+UseStringDeduplication"
]
```

### הגדרות אבטחה
- השתמש במשתני סביבה עבור אישורים
- הגבל הרשאות המשתמש בבסיס הנתונים
- השתמש בחיבורים מוצפנים כשאפשר

## תחזוקה ועדכונים

### עדכון השרת
1. הורד גרסה חדשה של MCPServer JAR
2. עדכן את הנתיב בהגדרות
3. הפעל מחדש את Amazon Q

### ניטור ולוגים
- בדוק לוגים ב-Amazon Q Developer
- עקוב אחר ביצועי השרת
- נטר שימוש בזיכרון ו-CPU

## סיכום

MCP Global-JDBC מספק ממשק חזק ונוח לעבודה עם בסיסי נתונים דרך Amazon Q. ההגדרה הנכונה והתצורה המותאמת מאפשרות עבודה יעילה ובטוחה עם מגוון בסיסי נתונים.
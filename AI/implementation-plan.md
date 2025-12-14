# Plan Implementacji SitLess - Szczegółowy Przewodnik

## Wprowadzenie

Ten dokument zawiera szczegółowy, krokowy plan implementacji aplikacji SitLess na zegarki Garmin. Każdy krok jest zaprojektowany tak, aby można było go zweryfikować przed przejściem dalej.

**Filozofia:** Małe, testowalne przyrosty funkcjonalności. Po każdym kroku powinieneś być w stanie uruchomić aplikację w symulatorze i zweryfikować, że działa poprawnie.

---

## Faza 0: Przygotowanie środowiska i zrozumienie podstaw

### Krok 0.1: Weryfikacja środowiska deweloperskiego
**Cel:** Upewnić się, że środowisko działa poprawnie

**Zadania:**
1. Sprawdź, czy Connect IQ SDK jest zainstalowany
2. Zbuduj aktualną wersję projektu (`Monkey C: Build for Device`)
3. Uruchom w symulatorze (`Monkey C: Run`)
4. Upewnij się, że widzisz domyślny ekran z małpką

**Test weryfikacyjny:**
- [ ] Aplikacja kompiluje się bez błędów
- [ ] Aplikacja uruchamia się w symulatorze
- [ ] Widzisz ikonę małpki na ekranie

### Krok 0.2: Dodanie wymaganych uprawnień
**Cel:** Skonfigurować manifest.xml z niezbędnymi uprawnieniami

**Zadania:**
1. Użyj `Monkey C: Edit Permissions` w VS Code
2. Dodaj uprawnienie `Background` (dla usługi w tle)
3. Dodaj uprawnienie `FitContributor` (dla dostępu do kroków - wymagane przez ActivityMonitor)

**Test weryfikacyjny:**
- [ ] `manifest.xml` zawiera sekcję `<iq:permissions>` z obydwoma uprawnieniami
- [ ] Aplikacja nadal się kompiluje

---

## Faza 1: Wyświetlanie aktualnej liczby kroków (pierwszy milestone)

### Krok 1.1: Odczyt całkowitej liczby kroków z ActivityMonitor
**Cel:** Nauczyć się korzystać z API ActivityMonitor i wyświetlić dane

**Plik:** `source/sitlessView.mc`

**Zadania:**
1. Dodaj import `Toybox.ActivityMonitor`
2. W funkcji `onUpdate()` pobierz dane z `ActivityMonitor.getInfo()`
3. Wyświetl liczbę kroków dziennych na ekranie (tekst)

**Kod koncepcyjny:**
```monkeyc
import Toybox.ActivityMonitor;

function onUpdate(dc as Dc) as Void {
    View.onUpdate(dc);

    var info = ActivityMonitor.getInfo();
    var steps = 0;
    if (info != null && info.steps != null) {
        steps = info.steps;
    }

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.drawText(
        dc.getWidth() / 2,
        dc.getHeight() / 2,
        Graphics.FONT_MEDIUM,
        "Steps: " + steps,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );
}
```

**Test weryfikacyjny:**
- [ ] Aplikacja wyświetla "Steps: X" gdzie X to liczba kroków
- [ ] W symulatorze: Simulation → Activity Data → ustaw kroki → wartość się aktualizuje

**Nauka:**
- Jak działa `ActivityMonitor.getInfo()`
- Jak rysować tekst bezpośrednio na `dc` (Device Context)
- Null-checking w Monkey C

### Krok 1.2: Usunięcie domyślnego layoutu i przejście na custom drawing
**Cel:** Pełna kontrola nad rysowaniem UI

**Pliki:**
- `source/sitlessView.mc`
- `resources/layouts/layout.xml`

**Zadania:**
1. Usuń `setLayout()` z `onLayout()` lub ustaw pusty layout
2. Wyczyść ekran przed rysowaniem w `onUpdate()`
3. Dodaj czyszczenie tła (czarny kolor dla oszczędności baterii AMOLED)

**Test weryfikacyjny:**
- [ ] Ekran pokazuje tylko tekst z krokami na czarnym tle
- [ ] Nie ma już obrazka małpki

### Krok 1.3: Implementacja bufora kroków - struktura danych
**Cel:** Przygotować mechanizm śledzenia kroków w oknie czasowym

**Nowy plik:** `source/StepBuffer.mc`

**Zadania:**
1. Utwórz klasę `StepBuffer`
2. Zaimplementuj strukturę do przechowywania próbek (timestamp + steps)
3. Dodaj metodę `addSample(totalSteps, timestamp)`
4. Dodaj metodę `getStepsInWindow(windowMinutes)` - oblicza różnicę kroków

**Struktura danych:**
```monkeyc
class StepBuffer {
    private var _samples as Array<Dictionary>;  // [{time: Moment, steps: Number}, ...]
    private var _maxSamples as Number;

    function initialize(maxSamples as Number) {
        _samples = [];
        _maxSamples = maxSamples;
    }

    function addSample(totalSteps as Number, time as Time.Moment) as Void {
        // Dodaj próbkę, usuń stare
    }

    function getStepsInWindow(windowMinutes as Number) as Number {
        // Znajdź najstarszą próbkę w oknie i oblicz różnicę
    }
}
```

**Test weryfikacyjny:**
- [ ] Klasa kompiluje się bez błędów
- [ ] Testy jednostkowe (jeśli możliwe) lub ręczna weryfikacja logiki

### Krok 1.4: Integracja StepBuffer z widokiem
**Cel:** Wyświetlić kroki z ostatnich 60 minut

**Pliki:**
- `source/sitlessApp.mc`
- `source/sitlessView.mc`

**Zadania:**
1. Utwórz instancję `StepBuffer` w `sitlessApp`
2. Przy każdym `onShow()` lub `onUpdate()` dodaj próbkę do bufora
3. Wyświetl zarówno kroki dzienne jak i kroki z okna 60min

**Test weryfikacyjny:**
- [ ] Aplikacja pokazuje dwie linie: "Daily: X" i "Last 60min: Y"
- [ ] Po wykonaniu kroków w symulatorze, wartość "Last 60min" rośnie
- [ ] Wartość "Last 60min" ≤ "Daily" (logiczna spójność)

### Krok 1.5: Optymalizacja wydajności widoku
**Cel:** Zastosować best practices dla lifecycle widgetu

**Plik:** `source/sitlessView.mc`

**Zadania:**
1. Dodaj flagę `_isVisible`
2. Ustaw ją w `onShow()` i `onHide()`
3. W `onUpdate()` sprawdź flagę przed rysowaniem
4. Przenieś obliczenia poza pętlę rysowania gdzie możliwe

**Kod:**
```monkeyc
private var _isVisible as Boolean = false;

function onShow() as Void {
    _isVisible = true;
}

function onHide() as Void {
    _isVisible = false;
}

function onUpdate(dc as Dc) as Void {
    if (!_isVisible) {
        return;
    }
    // rysowanie...
}
```

**Test weryfikacyjny:**
- [ ] Aplikacja działa jak poprzednio
- [ ] W logach nie ma nadmiarowych wywołań onUpdate gdy widget niewidoczny

---

## Faza 2: Wizualizacja postępu

### Krok 2.1: Prosty pasek postępu (progress bar)
**Cel:** Graficzna reprezentacja postępu kroków

**Plik:** `source/sitlessView.mc`

**Zadania:**
1. Oblicz procent: `stepsInWindow / targetSteps * 100`
2. Narysuj tło paska (szary prostokąt)
3. Narysuj wypełnienie (zielony/czerwony w zależności od postępu)

**Test weryfikacyjny:**
- [ ] Pasek postępu jest widoczny
- [ ] Pasek wypełnia się proporcjonalnie do kroków
- [ ] Przy 0 krokach pasek jest pusty, przy 50+ krokach pełny

### Krok 2.2: Dodanie kolorów i stanów wizualnych
**Cel:** Intuicyjne wskazanie stanu (ok/warning)

**Zadania:**
1. Zielony kolor gdy kroki >= cel
2. Czerwony/pomarańczowy gdy kroki < cel
3. Dodaj ikonę lub emoji (opcjonalnie)

**Test weryfikacyjny:**
- [ ] Kolor zmienia się w zależności od postępu
- [ ] UI jest czytelny zarówno na MIP jak i AMOLED (sprawdź różne urządzenia w symulatorze)

### Krok 2.3: Wyświetlanie dodatkowych informacji
**Cel:** Pełny UI widgetu

**Zadania:**
1. Wyświetl aktualną godzinę
2. Wyświetl cel kroków
3. Wyświetl czas do następnego sprawdzenia (opcjonalnie)

**Test weryfikacyjny:**
- [ ] Wszystkie elementy UI są widoczne i nie nachodzą na siebie
- [ ] Tekst jest czytelny na różnych rozmiarach ekranu

---

## Faza 3: Ustawienia użytkownika

### Krok 3.1: Definicja ustawień w XML
**Cel:** Przygotować strukturę ustawień dla Garmin Connect Mobile

**Nowy plik:** `resources/settings/settings.xml`

**Zadania:**
1. Utwórz katalog `resources/settings/`
2. Zdefiniuj ustawienia:
   - `minSteps` (Number, default: 50)
   - `timeWindow` (Number, default: 60)
   - `startHour` (Number, default: 7)
   - `endHour` (Number, default: 21)

**Struktura:**
```xml
<settings>
    <setting propertyKey="@Properties.minSteps" title="@Strings.SettingMinSteps">
        <settingConfig type="numeric" min="10" max="500" />
    </setting>
    <!-- ... pozostałe ustawienia -->
</settings>
```

**Test weryfikacyjny:**
- [ ] Plik kompiluje się bez błędów
- [ ] W symulatorze: Settings → App Settings pokazuje ustawienia

### Krok 3.2: Odczyt ustawień w kodzie
**Cel:** Używać ustawień użytkownika zamiast hardcoded wartości

**Nowy plik:** `source/SettingsManager.mc`

**Zadania:**
1. Utwórz klasę do zarządzania ustawieniami
2. Użyj `Application.Properties.getValue()` do odczytu
3. Dodaj fallback na wartości domyślne

**Test weryfikacyjny:**
- [ ] Zmiana ustawień w symulatorze wpływa na zachowanie aplikacji
- [ ] Przy braku ustawień używane są wartości domyślne

### Krok 3.3: Integracja ustawień z logiką aplikacji
**Cel:** Aplikacja respektuje ustawienia użytkownika

**Zadania:**
1. `StepBuffer` używa `timeWindow` z ustawień
2. Progress bar używa `minSteps` z ustawień
3. (Przygotowanie) Logika sprawdza `startHour`/`endHour`

**Test weryfikacyjny:**
- [ ] Zmiana `minSteps` zmienia wypełnienie paska
- [ ] Zmiana `timeWindow` wpływa na obliczenia

---

## Faza 4: Background Service

### Krok 4.1: Konfiguracja Background Service w manifeście
**Cel:** Przygotować infrastrukturę dla usługi w tle

**Plik:** `manifest.xml`

**Zadania:**
1. Dodaj deklarację service delegate w manifeście
2. Skonfiguruj typ uruchamiania (temporal)

**Test weryfikacyjny:**
- [ ] Manifest jest poprawny syntaktycznie
- [ ] Aplikacja kompiluje się

### Krok 4.2: Implementacja ServiceDelegate - szkielet
**Cel:** Podstawowa struktura usługi w tle

**Nowy plik:** `source/SitlessServiceDelegate.mc`

**Zadania:**
1. Utwórz klasę dziedziczącą z `System.ServiceDelegate`
2. Zaimplementuj `onTemporalEvent()` - główną metodę wywoływaną co 5min
3. Na razie tylko loguj wywołanie

**Test weryfikacyjny:**
- [ ] W logach symulatora widać wywołania co 5 minut
- [ ] Usługa nie crashuje

### Krok 4.3: Rejestracja usługi w aplikacji
**Cel:** Poprawne uruchamianie usługi

**Plik:** `source/sitlessApp.mc`

**Zadania:**
1. Dodaj `getServiceDelegate()` zwracający `SitlessServiceDelegate`
2. W `onStart()` zarejestruj temporal event

**Kod:**
```monkeyc
function getServiceDelegate() as [System.ServiceDelegate] {
    return [new SitlessServiceDelegate()];
}
```

**Test weryfikacyjny:**
- [ ] Usługa uruchamia się automatycznie
- [ ] Logi pokazują regularne wywołania

### Krok 4.4: Persystencja danych między wywołaniami
**Cel:** Zachować bufor kroków między uruchomieniami usługi

**Zadania:**
1. W `SitlessServiceDelegate.onTemporalEvent()`:
   - Odczytaj poprzedni bufor z `Application.Storage`
   - Dodaj nową próbkę
   - Zapisz zaktualizowany bufor
2. Uwzględnij limit 8KB na wpis storage

**Test weryfikacyjny:**
- [ ] Dane są zachowane między wywołaniami usługi
- [ ] Widget pokazuje poprawne dane po ponownym otwarciu
- [ ] Restart symulatora czyści dane (zgodnie z wymaganiami)

### Krok 4.5: Komunikacja Service → App
**Cel:** Przekazanie danych z usługi do widgetu

**Zadania:**
1. Użyj `Background.exit()` do przekazania danych
2. W `sitlessApp` zaimplementuj `onBackgroundData()`
3. Zaktualizuj stan aplikacji

**Test weryfikacyjny:**
- [ ] Widget pokazuje aktualne dane z usługi w tle
- [ ] Dane aktualizują się co 5 minut nawet bez interakcji

---

## Faza 5: Logika alertów

### Krok 5.1: Sprawdzanie warunków alertu
**Cel:** Logika decyzyjna dla powiadomień

**Nowy plik:** `source/AlertManager.mc`

**Zadania:**
1. Metoda `shouldAlert()` sprawdzająca:
   - Czy kroki < minSteps
   - Czy jesteśmy w godzinach aktywności
2. Na razie bez exclusions (DND, sleep, etc.)

**Test weryfikacyjny:**
- [ ] `shouldAlert()` zwraca true gdy kroki < cel w godzinach aktywności
- [ ] `shouldAlert()` zwraca false poza godzinami

### Krok 5.2: Implementacja exclusions
**Cel:** Blokowanie alertów w nieodpowiednich momentach

**Zadania:**
1. Sprawdź DND: `System.getDeviceSettings().doNotDisturb`
2. Sprawdź aktywność: `ActivityMonitor.getInfo().activityClass`
3. Sprawdź sleep mode (jeśli dostępne w API)
4. Sprawdź off-wrist (jeśli dostępne)

**Test weryfikacyjny:**
- [ ] Włącz DND w symulatorze → alert nie pojawia się
- [ ] Rozpocznij aktywność → alert nie pojawia się

### Krok 5.3: Wysyłanie wibracji
**Cel:** Powiadomienie haptyczne

**Zadania:**
1. Użyj `Attention.vibrate()`
2. Zdefiniuj wzór wibracji (krótki, delikatny)

**Test weryfikacyjny:**
- [ ] Wibracja jest wyzwalana gdy kroki < cel
- [ ] Wibracja nie jest zbyt agresywna

### Krok 5.4: Wyświetlanie komunikatu alertu
**Cel:** Wizualne powiadomienie

**Zadania:**
1. Utwórz widok alertu lub użyj notification API
2. Wyświetl komunikat "Time to move!" lub podobny
3. Dodaj tłumaczenia (EN/PL)

**Test weryfikacyjny:**
- [ ] Komunikat pojawia się razem z wibracją
- [ ] Komunikat jest w języku ustawionym na zegarku

---

## Faza 6: Funkcja Snooze

### Krok 6.1: Obsługa przycisków
**Cel:** Reagowanie na input użytkownika

**Nowy plik:** `source/SitlessInputDelegate.mc`

**Zadania:**
1. Utwórz klasę dziedziczącą z `WatchUi.InputDelegate`
2. Obsłuż `onKey()` - reakcja na przycisk Select
3. Zarejestruj delegate w `getInitialView()`

**Test weryfikacyjny:**
- [ ] Naciśnięcie przycisku jest wykrywane
- [ ] W logach widać info o naciśnięciu

### Krok 6.2: Logika snooze
**Cel:** Odkładanie alertów na 10 minut

**Zadania:**
1. Zapisz czas snooze w `Application.Storage`
2. W `AlertManager.shouldAlert()` sprawdź czy jesteśmy w okresie snooze
3. Po naciśnięciu Select ustaw snooze

**Test weryfikacyjny:**
- [ ] Po snooze alert nie pojawia się przez 10 minut
- [ ] Po 10 minutach logika alertów wraca do normy

---

## Faza 7: Glance View

### Krok 7.1: Konfiguracja Glance w manifeście
**Cel:** Włączyć obsługę Glance View

**Plik:** `manifest.xml`

**Zadania:**
1. Dodaj atrybut `glanceView` w manifeście (jeśli wymagane)

### Krok 7.2: Implementacja GlanceView
**Cel:** Skrócony widok na liście widgetów

**Nowy plik:** `source/SitlessGlanceView.mc`

**Zadania:**
1. Utwórz klasę dziedziczącą z `WatchUi.GlanceView`
2. Wyświetl minimalny UI: ikona + progress lub tekst
3. Zarejestruj w `sitlessApp.getGlanceView()`

**Test weryfikacyjny:**
- [ ] Glance view jest widoczny na liście widgetów
- [ ] Pokazuje aktualny postęp kroków

---

## Faza 8: Optymalizacje i testy

### Krok 8.1: Profilowanie pamięci
**Cel:** Upewnić się, że aplikacja mieści się w limitach

**Zadania:**
1. Użyj File → View memory w symulatorze
2. Sprawdź zużycie na różnych urządzeniach
3. Zoptymalizuj jeśli potrzeba

**Test weryfikacyjny:**
- [ ] Zużycie pamięci < 50% dostępnej na docelowych urządzeniach
- [ ] Brak memory warnings w logach

### Krok 8.2: Testy na różnych urządzeniach
**Cel:** Kompatybilność

**Zadania:**
1. Testuj na urządzeniu MIP (np. Fenix 6)
2. Testuj na urządzeniu AMOLED (np. Epix 2)
3. Sprawdź różne rozdzielczości ekranu

**Test weryfikacyjny:**
- [ ] UI jest czytelny na wszystkich testowanych urządzeniach
- [ ] Brak crashów na żadnym urządzeniu

### Krok 8.3: Testy baterii (długoterminowe)
**Cel:** Weryfikacja zużycia energii

**Zadania:**
1. Uruchom aplikację na prawdziwym zegarku (jeśli dostępny)
2. Monitoruj zużycie baterii przez 24h
3. Porównaj z baseline bez aplikacji

**Test weryfikacyjny:**
- [ ] Zużycie baterii < 5% dziennie więcej niż baseline

---

## Faza 9: Finalizacja

### Krok 9.1: Przegląd kodu i refactoring
**Zadania:**
1. Usuń nieużywany kod
2. Dodaj komentarze gdzie potrzeba
3. Sprawdź spójność nazewnictwa

### Krok 9.2: Lokalizacja
**Zadania:**
1. Upewnij się, że wszystkie stringi są w `strings.xml`
2. Dodaj tłumaczenia PL w `resources-pol/strings/strings.xml`

### Krok 9.3: Ikona aplikacji
**Zadania:**
1. Stwórz własną ikonę launcher
2. Zamień `monkey.png` na docelową grafikę

### Krok 9.4: Przygotowanie do publikacji
**Zadania:**
1. Ustaw finalną nazwę aplikacji
2. Przygotuj opis dla Connect IQ Store
3. Wykonaj build produkcyjny

---

## Podsumowanie kolejności implementacji

```
Faza 0: Środowisko (0.5h)
    └── 0.1 → 0.2

Faza 1: Wyświetlanie kroków [PIERWSZY MILESTONE] (2-3h)
    └── 1.1 → 1.2 → 1.3 → 1.4 → 1.5

Faza 2: Wizualizacja (1-2h)
    └── 2.1 → 2.2 → 2.3

Faza 3: Ustawienia (1-2h)
    └── 3.1 → 3.2 → 3.3

Faza 4: Background Service (3-4h)
    └── 4.1 → 4.2 → 4.3 → 4.4 → 4.5

Faza 5: Alerty (2-3h)
    └── 5.1 → 5.2 → 5.3 → 5.4

Faza 6: Snooze (1-2h)
    └── 6.1 → 6.2

Faza 7: Glance (1-2h)
    └── 7.1 → 7.2

Faza 8: Optymalizacje (2-3h)
    └── 8.1 → 8.2 → 8.3

Faza 9: Finalizacja (1-2h)
    └── 9.1 → 9.2 → 9.3 → 9.4
```

---

## Checkpointy (Momenty weryfikacji postępu)

| Checkpoint | Po kroku | Co weryfikujemy |
|------------|----------|-----------------|
| **CP1** | 1.4 | Widget pokazuje kroki dzienne i z ostatnich 60min |
| **CP2** | 2.3 | Pełny UI widgetu z paskiem postępu |
| **CP3** | 3.3 | Ustawienia działają i wpływają na aplikację |
| **CP4** | 4.5 | Background service zbiera dane w tle |
| **CP5** | 5.4 | Alerty wibracyjne działają |
| **CP6** | 6.2 | Snooze działa |
| **CP7** | 7.2 | Glance view pokazuje status |
| **CP8** | 8.3 | Aplikacja jest zoptymalizowana |
| **CP9** | 9.4 | Gotowe do publikacji |

---

## Notatki dla programisty

### Przydatne komendy symulatora
- `Ctrl+Shift+P` → "Monkey C: Run" - uruchomienie
- File → View memory - sprawdzenie pamięci
- Simulation → Activity Data - symulacja kroków

### Częste błędy
1. **Null pointer** - zawsze sprawdzaj `!= null` przed dostępem
2. **Out of memory** - monitoruj zużycie, ogranicz rozmiar buforów
3. **Watchdog timeout** - background service musi kończyć w <30ms

### Dokumentacja
- API: https://developer.garmin.com/connect-iq/api-docs/
- Programmer's Guide: https://developer.garmin.com/connect-iq/programmers-guide/

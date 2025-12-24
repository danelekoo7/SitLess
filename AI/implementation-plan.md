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

### Krok 0.2: Dodanie wymaganych uprawnień ✅ UKOŃCZONE
**Cel:** Skonfigurować manifest.xml z niezbędnymi uprawnieniami

**Zadania:**
1. Użyj `Monkey C: Edit Permissions` w VS Code
2. Dodaj uprawnienie `Background` (dla usługi w tle)

**UWAGA:** `FitContributor` NIE jest wymagane dla odczytu kroków. To uprawnienie służy do *zapisywania* danych do plików FIT, nie do odczytu. Moduł `ActivityMonitor` nie wymaga żadnych specjalnych uprawnień - jest dostępny bezpośrednio jako część API Connect IQ.

**Test weryfikacyjny:**
- [x] `manifest.xml` zawiera sekcję `<iq:permissions>` z uprawnieniem `Background`
- [x] Aplikacja nadal się kompiluje

---

## Faza 1: Wyświetlanie aktualnej liczby kroków (pierwszy milestone)

### Krok 1.1 + 1.2: Odczyt kroków i custom drawing ✅ UKOŃCZONE
**Cel:** Wyświetlić liczbę kroków z ActivityMonitor na czarnym tle

**Plik:** `source/sitlessView.mc`

**Co zostało zrobione:**
1. Dodano import `Toybox.ActivityMonitor`
2. Usunięto `setLayout()` - rysujemy bezpośrednio na `dc`
3. Czarne tło (oszczędność baterii AMOLED)
4. Wyświetlanie kroków dziennych

**UWAGA - Symulator:** Symulator Connect IQ nie przekazuje poprawnie wartości kroków do ActivityMonitor dla widgetów (zawsze pokazuje 0). Testowanie na prawdziwym urządzeniu (FR 255) potwierdza, że kod działa poprawnie.

**Test weryfikacyjny:**
- [x] Aplikacja wyświetla "Steps: X" gdzie X to liczba kroków
- [x] Na prawdziwym urządzeniu (FR 255) wartość jest poprawna
- [x] Czarne tło, biały tekst

### Krok 1.3: Implementacja bufora kroków - struktura danych ✅ UKOŃCZONE
**Cel:** Przygotować mechanizm śledzenia kroków w oknie czasowym

**Nowy plik:** `source/StepBuffer.mc`

**Co zostało zrobione:**
1. Utworzono klasę `StepBuffer` z metodami:
   - `addSample(totalSteps, time)` - dodaje próbkę do bufora
   - `getStepsInWindow(windowMinutes)` - oblicza kroki w oknie czasowym
   - `getSampleCount()` - zwraca liczbę próbek
   - `getLatestSteps()` - zwraca ostatnią wartość kroków
   - `toArray()` / `fromArray()` - serializacja dla Storage (przygotowanie do Fazy 4)
2. Obsługa midnight reset (gdy kroki dzienne się resetują)
3. Zwraca -1 gdy brak wystarczających danych (< 2 próbki)

**Test weryfikacyjny:**
- [x] Klasa kompiluje się bez błędów
- [x] Logika działa poprawnie na urządzeniu

### Krok 1.4: Integracja StepBuffer z widokiem ✅ UKOŃCZONE
**Cel:** Wyświetlić kroki z ostatnich 60 minut

**Pliki:**
- `source/sitlessApp.mc`
- `source/sitlessView.mc`

**Co zostało zrobione:**
1. Instancja `StepBuffer` utworzona w `sitlessApp` (15 próbek = ~75min)
2. Metoda `getStepBuffer()` udostępnia bufor dla widoku
3. Próbka dodawana w `onShow()` widoku
4. Wyświetlanie "Daily: X" i "Last 60min: Y" (lub "..." gdy < 2 próbki)

**UWAGA:** Aktualnie próbki dodawane są tylko przy otwieraniu widgetu. Pełne działanie wymaga Background Service (Faza 4), który będzie dodawał próbki automatycznie co ~5 min.

**Test weryfikacyjny:**
- [x] Aplikacja pokazuje dwie linie: "Daily: X" i "Last 60min: Y"
- [x] Przy < 2 próbkach pokazuje "..." z liczbą próbek
- [x] Wartość "Last 60min" ≤ "Daily" (logiczna spójność)

### Krok 1.5: Optymalizacja wydajności widoku ✅ UKOŃCZONE
**Cel:** Zastosować best practices dla lifecycle widgetu

**Plik:** `source/sitlessView.mc`

**Co zostało zrobione:**
1. Dodano flagę `_isVisible` (domyślnie `false`)
2. Ustawiana na `true` w `onShow()`, na `false` w `onHide()`
3. `onUpdate()` zwraca natychmiast gdy `!_isVisible`

**Test weryfikacyjny:**
- [x] Aplikacja działa jak poprzednio
- [x] Brak nadmiarowych renderowań gdy widget niewidoczny

---

## Faza 2: Wizualizacja postępu ✅ UKOŃCZONE

### Krok 2.1 + 2.2 + 2.3: Pasek postępu z kolorami i nowym layoutem ✅ UKOŃCZONE
**Cel:** Graficzna reprezentacja postępu kroków

**Plik:** `source/sitlessView.mc`

**Co zostało zrobione:**
1. Dodano stałą `DEFAULT_STEP_GOAL = 50`
2. Nowy layout UI (od góry do dołu):
   - Daily steps (szary, mały font)
   - Główna wartość "X / 50" (duży font, kolorowy)
   - Pasek postępu (70% szerokości, 12px wysokości)
   - Etykieta "last 60 min" (szary, mały font)
3. Logika kolorów:
   - Zielony gdy >= 50 kroków (cel osiągnięty)
   - Czerwony gdy < 50 kroków (cel nieosiągnięty)
   - Szary gdy brak danych (< 2 próbki)

**Test weryfikacyjny:**
- [x] Pasek postępu jest widoczny
- [x] Pasek wypełnia się proporcjonalnie do kroków
- [x] Kolor zmienia się w zależności od postępu
- [x] Szary pasek przy braku danych

**UWAGA:** Testowanie utrudnione bez Background Service - próbki dodawane tylko przy otwieraniu widgetu. Następna faza (4) rozwiąże ten problem.

---

## Faza 3: Ustawienia użytkownika ⏳ W TRAKCIE

**Filozofia:** Małe, testowalne kroki. Najpierw UI ustawień, potem integracja z logiką.

### Krok 3.1: Minimalny settings.xml z jednym ustawieniem (minSteps) ✅ UKOŃCZONE
**Cel:** Wyświetlić okno ustawień w Garmin Connect Mobile z jednym polem

**Co zostało zrobione:**
1. Utworzono `resources/settings/settings.xml` z elementami `<properties>` i `<settings>` w jednym pliku (format zalecany przez społeczność Connect IQ)
2. Dodano string `minStepsTitle` do `resources/strings/strings.xml`

**UWAGA - Format pliku:** Connect IQ pozwala na dwa podejścia:
- Osobne pliki `properties.xml` i `settings.xml`
- Jeden plik z root elementem `<resources>` zawierający `<properties>` i `<settings>` (użyty w tym projekcie)

**UWAGA - Cache symulatora:** Jeśli ustawienia nie są widoczne w symulatorze, usuń folder `%TEMP%\GARMIN` i przebuduj projekt.

**Test weryfikacyjny:**
- [x] Zbuduj projekt: "Monkey C: Build for Device"
- [x] Uruchom w symulatorze: "Monkey C: Run"
- [x] File > Edit Persistent Storage > Edit Application Properties
- [x] Widoczne pole "Step Goal" z wartością 50
- [x] Zmiana wartości zapisuje się poprawnie

### Krok 3.2: Odczyt minSteps w sitlessView
**Cel:** Zastąpić hardcoded `DEFAULT_STEP_GOAL` wartością z ustawień

**Plik:** `source/sitlessView.mc`

**Zmiany:**
1. Dodać import: `import Toybox.Application.Properties;`
2. Dodać metodę:
```monkeyc
private function getMinSteps() as Number {
    try {
        var value = Properties.getValue("minSteps");
        if (value != null && value instanceof Number) {
            return value as Number;
        }
    } catch (e) {
        System.println("SitLess: Error reading minSteps");
    }
    return 50;
}
```
3. Zastąpić wszystkie `DEFAULT_STEP_GOAL` wywołaniem `getMinSteps()`

**Test weryfikacyjny:**
- [x] Widget wyświetla "X / 50"
- [x] Zmień minSteps na 100 w ustawieniach (symulator)
- [x] Po ponownym otwarciu widget wyświetla "X / 100"

### Krok 3.2a: Menu ustawień na zegarku ✅ UKOŃCZONE
**Cel:** Umożliwić zmianę ustawień bezpośrednio z poziomu zegarka (bez Garmin Connect Mobile)

**Nowe pliki:**
1. `source/SitlessInputDelegate.mc` - obsługa przycisku MENU (długie przytrzymanie UP)
2. `source/SitlessSettingsMenu.mc` - delegat menu i picker do edycji wartości

**Modyfikacje:**
1. `source/sitlessApp.mc` - rejestracja InputDelegate w `getInitialView()`
2. `resources/strings/strings.xml` - dodane etykiety `SettingsTitle` i `StepGoalLabel`

**Co zostało zrobione:**

1. **SitlessInputDelegate.mc:**
   - Klasa `SitlessInputDelegate` dziedzicząca z `BehaviorDelegate`
   - Metoda `onMenu()` tworząca `Menu2` programowo (bez pliku XML)
   - Menu wyświetla aktualną wartość Step Goal jako sublabel

2. **SitlessSettingsMenu.mc:**
   - `SitlessMenuDelegate` - obsługa wyboru z menu
   - `StepGoalPickerFactory` - generowanie wartości 10-500 w krokach co 10
   - `StepGoalPicker` - widok pickera z tytułem
   - `StepGoalPickerDelegate` - zapis wartości do Properties

3. **Rejestracja w sitlessApp.mc:**
```monkeyc
return [new sitlessView(), new SitlessInputDelegate()] as [Views, InputDelegates];
```

**UWAGA - Symulator:** Symulator Connect IQ nie obsługuje długiego przytrzymania przycisków. Menu działa poprawnie na prawdziwym urządzeniu.

**UWAGA - Implementacja:** Użyto `Menu2` tworzone programowo + `Picker` z `PickerFactory` zamiast deprecated `NumberPicker`.

**Test weryfikacyjny:**
- [x] Długie przytrzymanie UP otwiera menu (na prawdziwym urządzeniu)
- [x] Menu zawiera opcję "Step Goal" z aktualną wartością
- [x] Wybór otwiera picker z wartościami 10-500 (krok 10)
- [x] Zmiana wartości na zegarku jest zapisywana do Properties
- [x] Po zapisie widget wyświetla nową wartość
- [x] Test na prawdziwym urządzeniu (FR 255)

### Krok 3.3: Dodanie ustawienia timeWindow ✅ UKOŃCZONE
**Cel:** Drugie ustawienie - okno czasowe (dostępne w GCM i na zegarku)

**Co zostało zrobione:**
1. `resources/settings/settings.xml` - dodano property `timeWindow` (domyślna wartość: 60)
2. `resources/settings/settings.xml` - dodano setting z zakresem 30-120 minut
3. `resources/strings/strings.xml` - dodano `timeWindowTitle`

**Test weryfikacyjny:**
- [x] Dwa pola widoczne w GCM: "Step Goal" i "Time Window (min)"
- [x] Domyślne wartości: 50 i 60

### Krok 3.3a: Menu Time Window na zegarku ✅ UKOŃCZONE
**Cel:** Dodać Time Window do menu ustawień na zegarku

**ZASADA:** Każde nowe ustawienie musi być od razu dostępne również z poziomu menu na zegarku (długie przytrzymanie UP).

**Co zostało zrobione:**
1. `resources/strings/strings.xml` - dodano string `TimeWindowLabel`
2. `source/SitlessInputDelegate.mc` - dodano element menu dla Time Window + metodę `getTimeWindow()`
3. `source/SitlessSettingsMenu.mc` - dodano obsługę Time Window:
   - Rozszerzono `onSelect()` o `:timeWindow`
   - Dodano `openTimeWindowPicker()` i `getTimeWindow()`
   - Dodano klasy `TimeWindowPicker` i `TimeWindowPickerDelegate`
4. Ujednolicono obsługę błędów - wszystkie bloki catch używają `System.println()` z kontekstem

**Test weryfikacyjny:**
- [x] Menu na zegarku pokazuje dwie opcje: "Step Goal" i "Time Window"
- [x] Picker Time Window pokazuje wartości 30-120 (krok 10)
- [x] Zmiana wartości jest zapisywana i widoczna w widgecie

### Krok 3.4: Odczyt timeWindow w sitlessView ✅ UKOŃCZONE
**Cel:** Użyć timeWindow w widoku

**Plik:** `source/sitlessView.mc`

**Co zostało zrobione:**
1. Dodano metodę `getTimeWindow()` (analogicznie do `getMinSteps()`)
2. Zastąpiono `DEFAULT_WINDOW_MINUTES` wywołaniem `getTimeWindow()`
3. Usunięto stałą `DEFAULT_WINDOW_MINUTES`

**Test weryfikacyjny:**
- [x] Widget wyświetla "last 60 min"
- [x] Zmień timeWindow na 90
- [x] Po ponownym otwarciu wyświetla "last 90 min"

### Krok 3.5: Dodanie ustawień startHour i endHour
**Cel:** Godziny aktywności (do przyszłego użycia w alertach Faza 5)

**Modyfikacje:**
1. `resources/settings/properties.xml` - dodać:
```xml
<property id="startHour" type="number">7</property>
<property id="endHour" type="number">21</property>
```

2. `resources/settings/settings.xml` - dodać:
```xml
<setting propertyKey="@Properties.startHour" title="@Strings.startHourTitle">
    <settingConfig type="numeric" min="0" max="23" />
</setting>
<setting propertyKey="@Properties.endHour" title="@Strings.endHourTitle">
    <settingConfig type="numeric" min="0" max="23" />
</setting>
```

3. `resources/strings/strings.xml` - dodać:
```xml
<string id="startHourTitle">Active Hours Start</string>
<string id="endHourTitle">Active Hours End</string>
```

**Test weryfikacyjny:**
- [ ] Cztery pola widoczne w ustawieniach
- [ ] Domyślne wartości: 50, 60, 7, 21

### Krok 3.6: Utworzenie modułu SettingsManager
**Cel:** Centralizacja odczytu ustawień (DRY)

**Nowy plik:** `source/SettingsManager.mc`

```monkeyc
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.System;

(:typecheck(disableBackgroundCheck))
module SettingsManager {
    const DEFAULT_MIN_STEPS = 50;
    const DEFAULT_TIME_WINDOW = 60;
    const DEFAULT_START_HOUR = 7;
    const DEFAULT_END_HOUR = 21;

    function getMinSteps() as Number {
        return getNumberSetting("minSteps", DEFAULT_MIN_STEPS);
    }

    function getTimeWindow() as Number {
        return getNumberSetting("timeWindow", DEFAULT_TIME_WINDOW);
    }

    function getStartHour() as Number {
        return getNumberSetting("startHour", DEFAULT_START_HOUR);
    }

    function getEndHour() as Number {
        return getNumberSetting("endHour", DEFAULT_END_HOUR);
    }

    function getRequiredBufferSize() as Number {
        var timeWindow = getTimeWindow();
        return (timeWindow / 5) + 3;  // +3 na margines bezpieczeństwa
    }

    private function getNumberSetting(key as String, defaultValue as Number) as Number {
        try {
            var value = Properties.getValue(key);
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading " + key);
        }
        return defaultValue;
    }
}
```

**Modyfikacja:** `source/sitlessView.mc`
- Usunąć lokalne metody `getMinSteps()` i `getTimeWindow()`
- Zastąpić wywołaniami `SettingsManager.getMinSteps()` itd.

**Test weryfikacyjny:**
- [ ] Widget działa jak wcześniej
- [ ] Ustawienia nadal poprawnie odczytywane

### Krok 3.7: Dynamiczny rozmiar bufora w sitlessApp
**Cel:** Rozmiar bufora oparty na timeWindow

**Plik:** `source/sitlessApp.mc`

**Zmiany:**
1. W `getInitialView()` przed `loadStepBufferFromStorage()` dodać:
```monkeyc
syncSettingsToStorage();
```

2. Dodać metodę:
```monkeyc
(:typecheck(disableBackgroundCheck))
private function syncSettingsToStorage() as Void {
    var bufferSize = SettingsManager.getRequiredBufferSize();
    Storage.setValue("maxSamples", bufferSize);
    System.println("SitLess: Synced maxSamples=" + bufferSize);
}
```

3. W `getStepBuffer()` zmienić `new StepBuffer(15)` na:
```monkeyc
_stepBuffer = new StepBuffer(SettingsManager.getRequiredBufferSize());
```

**Test weryfikacyjny:**
- [ ] timeWindow=30 → bufor 9 próbek ((30/5)+3)
- [ ] timeWindow=120 → bufor 27 próbek ((120/5)+3)
- [ ] W logach widoczny poprawny rozmiar bufora

### Krok 3.8: Dynamiczny rozmiar bufora w SitlessServiceDelegate
**Cel:** Background service używa rozmiaru z Storage

**Plik:** `source/SitlessServiceDelegate.mc`

**Zmiana w `onTemporalEvent()`** - zastąpić:
```monkeyc
var maxSamples = 15;
```
Na:
```monkeyc
var maxSamples = 15; // default
var storedMaxSamples = Storage.getValue("maxSamples");
if (storedMaxSamples != null && storedMaxSamples instanceof Number) {
    maxSamples = storedMaxSamples as Number;
}
```

**Test weryfikacyjny:**
- [ ] Ustaw timeWindow na 90 (oczekiwany rozmiar: 21)
- [ ] Otwórz widget (synchronizuje ustawienia)
- [ ] Poczekaj na background service
- [ ] W logach: liczba próbek ≤ 21

### Krok 3.9: Polskie tłumaczenia
**Cel:** Lokalizacja ustawień

**Nowy plik:** `resources-pol/strings/strings.xml`

```xml
<strings>
    <string id="AppName">sitless</string>
    <string id="minStepsTitle">Cel kroków</string>
    <string id="timeWindowTitle">Okno czasowe (min)</string>
    <string id="startHourTitle">Początek aktywności</string>
    <string id="endHourTitle">Koniec aktywności</string>
</strings>
```

**Test weryfikacyjny:**
- [ ] Zmień język symulatora na polski
- [ ] Etykiety ustawień po polsku

### Krok 3.10: Walidacja ustawień (opcjonalny)
**Cel:** Ochrona przed nieprawidłowymi wartościami

**Plik:** `source/SettingsManager.mc`

Dodać walidację zakresów w każdej metodzie get*:
```monkeyc
function getMinSteps() as Number {
    var value = getNumberSetting("minSteps", DEFAULT_MIN_STEPS);
    if (value < 10) { return 10; }
    if (value > 500) { return 500; }
    return value;
}
```

**Test weryfikacyjny:**
- [ ] Ręcznie ustaw minSteps na 5 (poniżej minimum)
- [ ] Aplikacja używa wartości 10 (skorygowanej)

### Diagram zależności Fazy 3:
```
Krok 3.1 ──> Krok 3.2 ──┐
                        │
Krok 3.3 ──> Krok 3.4 ──┼──> Krok 3.6 ──> Krok 3.7 ──> Krok 3.8
                        │
Krok 3.5 ──────────────┘

Krok 3.9 (niezależny - po 3.5)
Krok 3.10 (po 3.6)
```

---

## Faza 4: Background Service ✅ UKOŃCZONE

### Krok 4.1: Konfiguracja Background Service w manifeście ✅ UKOŃCZONE
**Cel:** Przygotować infrastrukturę dla usługi w tle

**Plik:** `manifest.xml`

**Co zostało zrobione:**
1. Deklaracja service delegate dodana w manifeście
2. Uprawnienie `Background` już było skonfigurowane w Fazie 0

**Test weryfikacyjny:**
- [x] Manifest jest poprawny syntaktycznie
- [x] Aplikacja kompiluje się

### Krok 4.2: Implementacja ServiceDelegate ✅ UKOŃCZONE
**Cel:** Podstawowa struktura usługi w tle

**Plik:** `source/SitlessServiceDelegate.mc`

**Co zostało zrobione:**
1. Klasa `SitlessServiceDelegate` dziedzicząca z `System.ServiceDelegate`
2. Metoda `onTemporalEvent()` wywoływana co ~5min:
   - Odczytuje kroki z `ActivityMonitor.getInfo()`
   - Pobiera aktualny timestamp
   - Ładuje bufor z `Storage.getValue("stepBuffer")`
   - Dodaje nową próbkę jako `Dictionary` z polami `time` i `steps`
   - Utrzymuje maksymalnie 15 próbek (~75min danych)
   - Zapisuje zaktualizowany bufor do Storage
   - **Rejestruje następny temporal event** (krytyczne - temporal events są one-shot!)
   - Wywołuje `Background.exit()` z danymi dla głównej aplikacji
3. Logowanie dla debugowania (`System.println()`)

**Test weryfikacyjny:**
- [x] W logach symulatora widać wywołania co 5 minut
- [x] Usługa nie crashuje

### Krok 4.3: Rejestracja usługi w aplikacji ✅ UKOŃCZONE
**Cel:** Poprawne uruchamianie usługi

**Plik:** `source/sitlessApp.mc`

**Co zostało zrobione:**
1. Metoda `getServiceDelegate()` zwracająca `[new SitlessServiceDelegate()]`
2. Metoda `registerNextTemporalEvent()` rejestrująca zdarzenie za 5 minut
3. Rejestracja temporal event w `getInitialView()` (nie w `onStart()` - bo `onStart()` jest też wywoływany dla background)
4. Adnotacja `(:background)` na klasie `sitlessApp` dla kompatybilności z background context

**Test weryfikacyjny:**
- [x] Usługa uruchamia się automatycznie
- [x] Logi pokazują regularne wywołania

### Krok 4.4: Persystencja danych między wywołaniami ✅ UKOŃCZONE
**Cel:** Zachować bufor kroków między uruchomieniami usługi

**Co zostało zrobione:**
1. W `SitlessServiceDelegate.onTemporalEvent()`:
   - Odczyt bufora: `Storage.getValue("stepBuffer")`
   - Zapis bufora: `Storage.setValue("stepBuffer", samples)`
   - Używanie `Application.PropertyValueType` dla type safety
2. W `sitlessApp`:
   - Metoda `loadStepBufferFromStorage()` konwertuje zapisane dane (timestamp jako Number) na format StepBuffer (timestamp jako `Time.Moment`)

**Test weryfikacyjny:**
- [x] Dane są zachowane między wywołaniami usługi
- [x] Widget pokazuje poprawne dane po ponownym otwarciu

### Krok 4.5: Komunikacja Service → App ✅ UKOŃCZONE
**Cel:** Przekazanie danych z usługi do widgetu

**Co zostało zrobione:**
1. `Background.exit(result)` w ServiceDelegate przekazuje dane:
   - `steps` - aktualna liczba kroków
   - `sampleCount` - ilość próbek w buforze
   - `timestamp` - czas próbki
2. `onBackgroundData(data)` w `sitlessApp`:
   - Odbiera dane z background service
   - Przeładowuje bufor z Storage
   - Wywołuje `WatchUi.requestUpdate()` dla odświeżenia UI

**Test weryfikacyjny:**
- [x] Widget pokazuje aktualne dane z usługi w tle
- [x] Dane aktualizują się co 5 minut nawet bez interakcji

### Krok 4.6 (dodany): Aktualizacja ikony launchera ✅ UKOŃCZONE
**Cel:** Lepsza widoczność ikony aplikacji

**Plik:** `resources/drawables/launcher_icon.svg`

**Co zostało zrobione:**
- Zwiększono rozmiar ikony dla lepszej widoczności

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

**ZMIANA KOLEJNOŚCI:** Background Service (Faza 4) przeniesiony przed Ustawienia (Faza 3), ponieważ jest niezbędny do testowania bufora kroków.

```
Faza 0: Środowisko ✅
    └── 0.1 → 0.2

Faza 1: Wyświetlanie kroków ✅
    └── 1.1 → 1.2 → 1.3 → 1.4 → 1.5

Faza 2: Wizualizacja ✅
    └── 2.1 → 2.2 → 2.3

Faza 4: Background Service ✅
    └── 4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6

Faza 3: Ustawienia ⏳ W TRAKCIE
    └── 3.1 ✅ → 3.2 ✅ → 3.2a ✅ → 3.3 ⏳ → 3.4 → 3.5 → ...

Faza 5: Alerty
    └── 5.1 → 5.2 → 5.3 → 5.4

Faza 6: Snooze
    └── 6.1 → 6.2

Faza 7: Glance
    └── 7.1 → 7.2

Faza 8: Optymalizacje
    └── 8.1 → 8.2 → 8.3

Faza 9: Finalizacja
    └── 9.1 → 9.2 → 9.3 → 9.4
```

---

## Checkpointy (Momenty weryfikacji postępu)

| Checkpoint | Po fazie | Co weryfikujemy | Status |
|------------|----------|-----------------|--------|
| **CP1** | Faza 1 | Widget pokazuje kroki dzienne i z ostatnich 60min | ✅ |
| **CP2** | Faza 2 | Pełny UI widgetu z paskiem postępu | ✅ |
| **CP3** | Faza 4 | Background service zbiera dane w tle | ✅ |
| **CP4** | Faza 3 | Ustawienia działają i wpływają na aplikację | ⏳ NASTĘPNY |
| **CP5** | Faza 5 | Alerty wibracyjne działają | |
| **CP6** | Faza 6 | Snooze działa | |
| **CP7** | Faza 7 | Glance view pokazuje status | |
| **CP8** | Faza 8 | Aplikacja jest zoptymalizowana | |
| **CP9** | Faza 9 | Gotowe do publikacji | |

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

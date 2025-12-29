# Dokument wymagań produktu (PRD) - SitLess

## 1. Przegląd produktu
**SitLess** to aplikacja typu widget (z obsługą widoku Glance) na smartwatche Garmin, której głównym celem jest przeciwdziałanie siedzącemu trybowi życia. W odróżnieniu od systemowych rozwiązań Garmin, SitLess oferuje mniej restrykcyjne i bardziej konfigurowalne podejście do przypominania o ruchu.

Aplikacja działa w tle, monitorując liczbę kroków w zadanym oknie czasowym (okno kroczące). Jeśli użytkownik nie osiągnie zdefiniowanego minimum kroków, otrzyma dyskretne powiadomienie wibracyjne z możliwością drzemki. Konfiguracja parametrów odbywa się wyłącznie przez aplikację mobilną Garmin Connect, co upraszcza interfejs na samym zegarku.

**Model biznesowy:** Free (darmowa).
**Platformy:** Zegarki Garmin z obsługą Connect IQ (ekrany MIP oraz AMOLED).
**Języki MVP:** Angielski (EN) i Polski (PL).

## 2. Problem użytkownika
Współczesna praca biurowa oraz styl życia sprzyjają długotrwałemu przesiadywaniu, co negatywnie wpływa na zdrowie (bóle kręgosłupa, ryzyko chorób sercowo-naczyniowych).

Istniejące rozwiązania systemowe (Garmin Move Alert) mają następujące wady:
*   **Zbyt wysoki próg wejścia:** Wymagają znacznej aktywności, aby wyczyścić pasek ruchu, co jest trudne do wykonania w biurze bez odchodzenia od biurka na dłużej.
*   **Brak elastyczności:** Użytkownik nie może zdefiniować własnych godzin pracy ani minimalnej liczby kroków.
*   **Irytacja:** Powiadomienia często pojawiają się w nieodpowiednich momentach (np. podczas jazdy samochodem lub w nocy, jeśli DND nie jest idealnie skonfigurowane).

**Rozwiązanie SitLess:** Umożliwienie użytkownikowi zdefiniowania własnych celów (np. 50 kroków na godzinę) oraz godzin aktywności, przy jednoczesnym inteligentnym blokowaniu powiadomień w sytuacjach, gdy ruch nie jest możliwy lub pożądany.

## 3. Wymagania funkcjonalne

### 3.1. Monitoring aktywności (Background Service)
*   Aplikacja musi działać jako usługa w tle (Background Service), uruchamiana cyklicznie (np. co 5 minut).
*   System musi utrzymywać wewnętrzny bufor danych (tablicę) do obliczania przyrostu kroków w oknie kroczącym (domyślnie ostatnie 60 minut), aby obejść ograniczenia API Garmin w dostępie do danych historycznych w czasie rzeczywistym.
*   Reset danych następuje przy ponownym uruchomieniu urządzenia (brak trwałego zapisu historii po restarcie).

### 3.2. Konfiguracja (Ustawienia)
Ustawienia dostępne z dwóch miejsc:
*   **Z poziomu zegarka:** Menu ustawień dostępne przez długie przytrzymanie przycisku UP w widgecie.
*   **Z poziomu telefonu:** Aplikacja Garmin Connect Mobile (Settings).

Parametry konfiguracyjne:
*   **Notifications enabled:** Włączenie/wyłączenie powiadomień wibracyjnych (domyślnie: ON). Gdy wyłączone, aplikacja działa tylko jako tracker kroków bez alertów — użytkownik może korzystać wyłącznie z podglądu danych.
*   **Min. steps:** Minimalna ilość kroków (domyślnie: 50).
*   **Time window:** Długość sprawdzanego okresu (domyślnie: 60 min).
*   **Start/End Time:** Godziny aktywności powiadomień (domyślnie: 07:00 - 21:00).

### 3.3. Powiadomienia i Interakcja
*   **Alert:** Wibracja (bez dźwięku) oraz komunikat tekstowy (np. "Time to move!").
*   **Snooze:** Możliwość odłożenia powiadomienia o konfigurowalny czas (domyślnie 60 minut) poprzez naciśnięcie przycisku SELECT. Ponowne naciśnięcie SELECT wyłącza snooze przed czasem. Wizualny wskaźnik przy przycisku SELECT pokazuje status snooze.
*   **Logika wykluczeń:** Powiadomienie NIE może zostać wysłane, jeśli:
    *   Włączony jest tryb "Do Not Disturb" (DND).
    *   Wykryto, że użytkownik śpi (Sleep Mode).
    *   Trwa rejestrowana aktywność sportowa.
    *   Zegarek nie znajduje się na nadgarstku (Off-wrist detection).

### 3.4. Interfejs Użytkownika (UI)
*   **Glance View:** Skrócony widok na tarczy zegarka pokazujący status (np. postęp w aktualnym oknie czasowym).
*   **Widget View:** Pełny widok po wejściu w widget, wizualizujący postęp (pasek postępu lub okrąg) oraz aktualną liczbę kroków w oknie.
*   **Obsługa ekranów:**
    *   Ciemny motyw (oszczędność energii).
    *   Ochrona przed wypaleniem dla ekranów AMOLED (pixel shifting lub wygaszanie).
*   **Sterowanie:** Obsługa wyłącznie przyciskami (kompatybilność z modelami bez dotyku). Przycisk "Select/Start" jako główny aktywator akcji (np. Snooze).

## 4. Granice produktu
*   **Brak historii długoterminowej:** Aplikacja nie służy do analizy trendów tygodniowych/miesięcznych. Dane są efemeryczne.
*   **Brak dźwięku:** Aplikacja polega wyłącznie na wibracjach.
*   **Dokładność:** Aplikacja polega na systemowym liczniku kroków Garmin; nie implementuje własnego algorytmu detekcji kroków z akcelerometru.
*   **Zależność od API:** Działanie w tle jest ograniczone przez limity systemu Connect IQ (np. częstotliwość wybudzania serwisu).

## 5. Historyjki użytkowników

| ID | Tytuł | Opis | Kryteria akceptacji |
| :--- | :--- | :--- | :--- |
| **US-001** | Konfiguracja parametrów | Jako pracownik biurowy, chcę ustawić minimalną liczbę kroków na 50 i okno czasowe na 60 minut, aby dostosować przypomnienia do mojego trybu pracy. | 1. Użytkownik może zmienić ustawienia z poziomu zegarka (długie przytrzymanie UP) lub w Garmin Connect.<br>2. Zmiana ustawień jest natychmiast stosowana.<br>3. Aplikacja używa nowych parametrów w kolejnym cyklu sprawdzania. |
| **US-002** | Monitoring w tle | Jako użytkownik, chcę, aby aplikacja zliczała moje kroki w tle, nawet gdy tarcza zegarka jest wyłączona, abym nie musiał o tym myśleć. | 1. Aplikacja uruchamia serwis w tle co ok. 5 minut.<br>2. Bufor kroków jest aktualizowany bez otwierania widgetu.<br>3. Bateria nie zużywa się nadmiernie (>5% dziennie). |
| **US-003** | Otrzymanie powiadomienia | Jako użytkownik, chcę poczuć wibrację i zobaczyć komunikat "Move!", gdy siedzę zbyt długo w godzinach aktywności, aby wstać i się rozruszać. | 1. Wibracja następuje tylko, gdy kroki < limit w zadanym oknie.<br>2. Powiadomienie pojawia się tylko w zdefiniowanych godzinach (np. 7-21).<br>3. Wyświetlany jest czytelny komunikat tekstowy. |
| **US-004** | Funkcja Snooze | Jako kierowca, chcę móc szybko wybrać opcję "Drzemka" po otrzymaniu alertu, aby powiadomienia były wstrzymane na konfigurowalny czas. | 1. Naciśnięcie przycisku "Select" przełącza (toggle) tryb snooze.<br>2. Powiadomienia są wstrzymane na czas z ustawienia `snoozeDuration` (domyślnie 60 min).<br>3. Ponowne naciśnięcie SELECT wyłącza snooze przed czasem.<br>4. Wizualny wskaźnik przy przycisku SELECT pokazuje status snooze (pomarańczowy = aktywny). |
| **US-005** | Blokowanie w nocy/DND | Jako użytkownik, nie chcę być budzony wibracjami, gdy śpię lub mam włączony tryb "Nie przeszkadzać". | 1. Jeśli status systemu to DND, powiadomienie nie jest wysyłane.<br>2. Jeśli system wykrywa sen, powiadomienie nie jest wysyłane.<br>3. Logika działa niezależnie od ustawionych godzin aktywności. |
| **US-006** | Wykrywanie braku zegarka | Jako użytkownik, nie chcę, aby zegarek wibrował na stole, gdy go nie noszę. | 1. Aplikacja sprawdza status czujnika tętna/noszenia.<br>2. Jeśli zegarek nie jest na ręku, alerty są wstrzymane. |
| **US-007** | Podgląd Glance | Jako posiadacz Fenixa, chcę widzieć postęp moich kroków na liście widgetów (Glance), aby szybko sprawdzić status bez wchodzenia w aplikację. | 1. Widok Glance pokazuje graficzną reprezentację (np. pasek) postępu.<br>2. Dane w Glance są aktualne (odświeżane przez serwis w tle). |
| **US-008** | Blokowanie podczas sportu | Jako biegacz, nie chcę otrzymywać powiadomień "Rusz się" podczas trwania innej aktywności sportowej. | 1. Aplikacja sprawdza flagę aktywności systemowej.<br>2. Jeśli aktywność trwa, sprawdzanie warunków jest wstrzymane. |
| **US-009** | Bezpieczna konfiguracja | Jako użytkownik, chcę mieć pewność, że tylko ja mogę zmieniać ustawienia mojej aplikacji poprzez moje uwierzytelnione konto Garmin. | 1. Dostęp do ustawień aplikacji jest możliwy tylko po zalogowaniu do aplikacji mobilnej Garmin Connect sparowanej z zegarkiem. |
| **US-010** | Wyłączenie powiadomień | Jako użytkownik, chcę mieć możliwość wyłączenia powiadomień wibracyjnych, aby korzystać z aplikacji tylko jako trackera kroków bez irytujących alertów czy konieczności włączania trybu DND. | 1. Ustawienie "Notifications enabled" jest dostępne w konfiguracji.<br>2. Domyślnie powiadomienia są włączone (ON).<br>3. Gdy wyłączone, aplikacja nie wysyła żadnych wibracji ani alertów.<br>4. Widget i Glance nadal wyświetlają dane o krokach. |

## 6. Metryki sukcesu
*   **Stabilność:** Aplikacja działa nieprzerwanie przez 24h bez systemowego "zabicia" procesu tła (crash rate < 1%).
*   **Zużycie baterii:** Instalacja aplikacji nie powoduje wzrostu zużycia baterii o więcej niż 3-5% w skali doby w porównaniu do stanu bez aplikacji.
*   **Skuteczność:** 100% poprawnych alertów w warunkach testowych (brak ruchu przez 60 min w godzinach aktywności).
*   **Brak "False Positives":** 0 powiadomień wysłanych w trybie DND lub podczas snu w trakcie testów nocnych.
*   **Kompatybilność UI:** Czytelność interfejsu potwierdzona na minimum jednym urządzeniu MIP (np. Fenix) i jednym AMOLED (np. Epix/Venu).
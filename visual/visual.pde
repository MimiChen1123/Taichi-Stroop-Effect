import javax.swing.JOptionPane;
import java.io.File;


ArrayList<Trial> trials = new ArrayList<Trial>();

int currentTrialIndex = 0;
Trial currentTrial;


// -------------------------
// Participant and CSV output
// -------------------------
String participantName = "anonymous";
String experimentDate = "";
String outputFileName = "";
String outputFolderName = "results";
PrintWriter output;


// -------------------------
// Experiment states
// -------------------------
// 0 = instruction
// 1 = Fruit-color mapping
// 2 = fixation
// 3 = trial running
// 4 = unused feedback state
// 5 = finished
int state = 0;


// -------------------------
// Timing variables
// -------------------------
int stateStartTime;
int trialStartTime;
int visualOnsetTime;

boolean visualShown = false;


// -------------------------
// Duration settings
// -------------------------
int fixationDuration = 500;


// -------------------------
// Fonts
// -------------------------
PFont regularFont;
PFont boldFont;


// -------------------------
// Five colors
// -------------------------
String[] colorNames = {
  "紅", "綠", "橘", "藍", "紫"
};

color[] colorValues = {
  color(220, 50, 50),     // Red
  color(40, 160, 70),     // Green
  color(255, 165, 0),     // Orange
  color(30, 144, 255),    // Blue
  color(140, 70, 180)     // Purple
};


// -------------------------
// Fruit words
// -------------------------
String[] objectWords = {
  "蘋果", "西瓜", "芒果", "藍莓", "葡萄"
};


// -------------------------
// User-defined fruit-color mapping
// ObjectToColorIndex[i] stores the color index mapped to objectWords[i].
// Example: ObjectToColorIndex[0] = 2 means 蘋果 -> 橘
// -------------------------
int[] ObjectToColorIndex = new int[objectWords.length];

boolean[] colorAlreadyUsed = new boolean[colorNames.length];

int currentMappingObjectIndex = 0;
String mappingWarning = "";

boolean mappingPreviewScreen = true;

// Press and hold H to show mapping hint.
boolean mappingHintVisible = false;

boolean experimentPrepared = false;
String preparationErrorMessage = "";


// -------------------------
// Response keys
// r = red
// g = green
// o = orange
// b = blue
// p = purple
// -------------------------
char[] responseKeys = {
  'r', 'g', 'o', 'b', 'p'
};


// ======================================================
// setup
// ======================================================
void setup() {
  size(900, 600);
  textAlign(CENTER, CENTER);

  regularFont = createFont("Arial", 24);
  boldFont = createFont("Arial Bold", 24);
  textFont(regularFont);

  for (int i = 0; i < ObjectToColorIndex.length; i++) {
    ObjectToColorIndex[i] = -1;
  }

  participantName = askParticipantName();
  experimentDate = nf(month(), 2) + nf(day(), 2);
  outputFileName = participantName + "_" + experimentDate + "_experiment_results.csv";
  prepareOutputFolder();

  println("==================================");
  println("Experiment initialized.");
  println("Participant: " + participantName);
  println("Date: " + experimentDate);
  println("==================================");
}


// ======================================================
// draw
// ======================================================
void draw() {
  background(245);

  if (state == 0) {
    drawInstruction();

  } else if (state == 1) {
    drawMappingScreen();

  } else if (state == 2) {
    drawFixation();
    checkFixationEnd();

  } else if (state == 3) {
    runTrial();

  } else if (state == 5) {
    drawFinished();
  }
}


// ======================================================
// Instruction screen
// ======================================================
void drawInstruction() {
  fill(30);

  textFont(regularFont);
  textSize(34);
  text("Experiment Instructions", width / 2, 65);

  textSize(22);
  text("Please judge the actual color displayed, not the meaning of the sentence.", width / 2, 130);
  text("The sentence may contain a color word or a fruit word.", width / 2, 170);
  text("Before the experiment, you will create your own fruit-color mapping.", width / 2, 210);

  textSize(22);
  fill(30);
  textFont(boldFont);
  text("Response Key Mapping:", width / 2, 275);

  drawColoredKeyMapping(320);

  textFont(boldFont);
  textSize(22);
  fill(30);
  text("Fruit Mapping:", width / 2, 395);

  if (currentMappingObjectIndex < objectWords.length) {
    textFont(regularFont);
    textSize(20);
    fill(80);
    text("Not completed yet.", width / 2, 440);
  } else {
    drawObjectMappingSummary(width / 2, 440);
  }

  if (preparationErrorMessage.length() > 0) {
    fill(200, 50, 50);
    textFont(regularFont);
    textSize(18);
    text(preparationErrorMessage, width / 2, 500);
  }

  textFont(regularFont);
  textSize(24);
  fill(30);

  if (currentMappingObjectIndex < objectWords.length) {
    text("Press M to start fruit-color mapping.", width / 2, 550);
  } else {
    text("Mapping completed. Press SPACE to start.", width / 2, 550);
  }
}


// ======================================================
// Fruit-color mapping screen
// ======================================================
void drawMappingScreen() {
  if (mappingPreviewScreen) {
    drawMappingPreviewScreen();
    return;
  }

  fill(30);
  textFont(boldFont);
  textSize(34);
  text("Fruit-Color Mapping", width / 2, 70);

  textFont(regularFont);
  textSize(22);
  text("Please assign one color to each fruit.", width / 2, 125);
  text("Each color can only be used once.", width / 2, 160);

  if (currentMappingObjectIndex < objectWords.length) {
    textFont(boldFont);
    textSize(32);
    fill(30);
    text("Current Fruit:", width / 2, 230);

    textSize(44);
    fill(0);
    text(objectWords[currentMappingObjectIndex], width / 2, 285);

    textFont(regularFont);
    textSize(22);
    fill(30);
    text("Press a key to assign its color:", width / 2, 355);

    drawAvailableColorKeys(410);

    if (mappingWarning.length() > 0) {
      fill(200, 50, 50);
      textSize(20);
      text(mappingWarning, width / 2, 500);
    }

  } else {
    textFont(boldFont);
    textSize(30);
    fill(30);
    text("Mapping completed!", width / 2, 210);

    // Keep mapping-completed result as original black text.
    drawObjectMappingSummary(width / 2, 310);

    textFont(regularFont);
    textSize(24);
    fill(30);
    text("Press SPACE to start the experiment.", width / 2, 500);
  }
}


// ======================================================
// Mapping preview screen
// Show all fruit words before matching.
// ======================================================
void drawMappingPreviewScreen() {
  fill(30);

  textFont(boldFont);
  textSize(34);
  text("Fruit Words Preview", width / 2, 70);

  textFont(regularFont);
  textSize(22);
  text("These are the fruit words that may appear in the experiment.", width / 2, 125);
  text("Please review them first. Then you will match each fruit with one color.", width / 2, 160);

  textFont(boldFont);
  textSize(26);
  fill(30);
  text("Fruit Words:", width / 2, 225);

  drawFruitWordPreview(280);

  textFont(boldFont);
  textSize(26);
  fill(30);
  text("Available Color Keys:", width / 2, 365);

  drawColoredKeyMapping(415);

  textFont(regularFont);
  textSize(24);
  fill(30);
  text("Press SPACE to start matching.", width / 2, 530);
}


// ======================================================
// Draw fruit words preview
// ======================================================
void drawFruitWordPreview(float y) {
  textFont(boldFont);
  textSize(28);

  float startX = width / 2 - 300;
  float gap = 150;

  for (int i = 0; i < objectWords.length; i++) {
    fill(30);
    text(objectWords[i], startX + gap * i, y);
  }

  textFont(regularFont);
}


// ======================================================
// Draw available color keys during mapping
// ======================================================
void drawAvailableColorKeys(float y) {
  textFont(boldFont);

  float startX = width / 2 - 310;
  float gap = 155;

  for (int i = 0; i < colorNames.length; i++) {
    if (colorAlreadyUsed[i]) {
      fill(170);
    } else {
      fill(colorValues[i]);
    }

    String label = Character.toUpperCase(responseKeys[i]) + " = " + colorNames[i];

    text(label, startX + gap * i, y);
  }

  textFont(regularFont);
}


// ======================================================
// Draw response key mapping
// ======================================================
void drawColoredKeyMapping(float y) {
  textFont(boldFont);

  float startX = width / 2 - 310;
  float gap = 155;

  fill(colorValues[0]);
  text("R = 紅", startX + gap * 0, y);

  fill(colorValues[1]);
  text("G = 綠", startX + gap * 1, y);

  fill(colorValues[2]);
  text("O = 橘", startX + gap * 2, y);

  fill(colorValues[3]);
  text("B = 藍", startX + gap * 3, y);

  fill(colorValues[4]);
  text("P = 紫", startX + gap * 4, y);

  textFont(regularFont);
}


// ======================================================
// Draw fruit mapping summary
// This is the original black one-line summary.
// Used on instruction / mapping completed screen.
// ======================================================
void drawObjectMappingSummary(float centerX, float y) {
  textFont(regularFont);
  textSize(18);

  String mappingText = "";

  for (int i = 0; i < objectWords.length; i++) {
    if (ObjectToColorIndex[i] != -1) {
      mappingText += objectWords[i] + " = " + colorNames[ObjectToColorIndex[i]];
    } else {
      mappingText += objectWords[i] + " = ?";
    }

    if (i < objectWords.length - 1) {
      mappingText += "  |  ";
    }
  }

  fill(50);
  text(mappingText, centerX, y);
}


// ======================================================
// Draw colored fruit mapping hint
// Each mapping is shown in one line.
// The whole block is centered around centerY.
// Example:
// 蘋果 = 紅   entire line is red
// 西瓜 = 綠   entire line is green
// ======================================================
void drawColoredObjectMappingSummaryForHint(float centerX, float centerY) {
  textFont(regularFont);
  textSize(22);

  float lineGap = 34;
  float middleOffset = (objectWords.length - 1) / 2.0;

  for (int i = 0; i < objectWords.length; i++) {
    float y = centerY + (i - middleOffset) * lineGap;

    if (ObjectToColorIndex[i] != -1) {
      int mappedColorIndex = ObjectToColorIndex[i];

      fill(colorValues[mappedColorIndex]);
      text(objectWords[i] + " = " + colorNames[mappedColorIndex], centerX, y);

    } else {
      fill(120);
      text(objectWords[i] + " = ?", centerX, y);
    }
  }
}


// ======================================================
// Fixation screen
// ======================================================
void drawFixation() {
  // Show mapping hint only when user holds H.
  if (mappingHintVisible) {
    drawColoredObjectMappingSummaryForHint(width - 80, height - 100);
  }

  textFont(regularFont);
  fill(0);
  textSize(60);
  text("+", width / 2, height / 2);
}


// ======================================================
// Check whether fixation has ended
// ======================================================
void checkFixationEnd() {
  if (millis() - stateStartTime >= fixationDuration) {
    startTrial();
  }
}


// ======================================================
// Start one trial
// ======================================================
void startTrial() {
  currentTrial = trials.get(currentTrialIndex);

  visualShown = false;
  currentTrial.hintUsed = false;

  trialStartTime = millis();
  visualOnsetTime = trialStartTime;

  state = 3;
}


// ======================================================
// Run current trial
// ======================================================
void runTrial() {
  int now = millis();

  if (now >= visualOnsetTime) {
    visualShown = true;
  }

  if (visualShown) {
    // Show mapping hint only when user holds H.
    if (mappingHintVisible) {
      drawColoredObjectMappingSummaryForHint(width - 80, height - 100);
    }

    // Show trial sentence
    textFont(regularFont);
    fill(currentTrial.inkColorValue);
    textSize(100);
    text(currentTrial.displayWord, width / 2, height / 2 - 40);

    // Show trial progress
    fill(120);
    textSize(18);
    text("Trial " + (currentTrialIndex + 1) + " / " + trials.size(), width / 2, height - 45);

  } else {
    fill(0);
    textSize(60);
    text("+", width / 2, height / 2);
  }
}


// ======================================================
// Finished screen
// ======================================================
void drawFinished() {
  textFont(regularFont);
  fill(30);
  textSize(34);
  text("The experiment is over. Thank you for participating!", width / 2, height / 2 - 30);

  textSize(20);
  text("Results saved to " + outputFolderName + "/" + outputFileName, width / 2, height / 2 + 30);
}


// ======================================================
// Keyboard response
// ======================================================
void keyPressed() {
  // -------------------------
  // Show mapping hint while holding H
  // -------------------------
  if (key == 'h' || key == 'H') {
    mappingHintVisible = true;

    if (state == 3 && currentTrial != null) {
      currentTrial.hintUsed = true;
    }

    return;
  }

  // -------------------------
  // Instruction screen
  // -------------------------
  if (state == 0) {

    // Start fruit-color mapping preview
    if (key == 'm' || key == 'M') {
      state = 1;
      mappingPreviewScreen = true;
      mappingWarning = "";
      preparationErrorMessage = "";
      return;
    }

    // Start experiment only after mapping is completed
    if (key == ' ') {
      if (currentMappingObjectIndex >= objectWords.length) {
        boolean prepared = prepareExperimentAfterMapping();

        if (prepared) {
          state = 2;
          stateStartTime = millis();
        }
      } else {
        preparationErrorMessage = "Please complete fruit-color mapping first by pressing M.";
        println(preparationErrorMessage);
      }

      return;
    }
  }

  // -------------------------
  // Fruit-color mapping stage
  // -------------------------
  if (state == 1) {

    // Preview screen: press SPACE to start actual matching
    if (mappingPreviewScreen) {
      if (key == ' ') {
        mappingPreviewScreen = false;
        mappingWarning = "";
      }
      return;
    }

    if (currentMappingObjectIndex < objectWords.length) {
      int colorIndex = getResponseIndex(key);

      if (colorIndex != -1) {
        if (colorAlreadyUsed[colorIndex]) {
          mappingWarning = colorNames[colorIndex] + " has already been used. Please choose another color.";
          return;
        }

        ObjectToColorIndex[currentMappingObjectIndex] = colorIndex;
        colorAlreadyUsed[colorIndex] = true;

        println("Mapping: " + objectWords[currentMappingObjectIndex] + " -> " + colorNames[colorIndex]);

        currentMappingObjectIndex++;
        mappingWarning = "";
        return;
      }
    } else {
      if (key == ' ') {
        boolean prepared = prepareExperimentAfterMapping();

        if (prepared) {
          state = 2;
          stateStartTime = millis();
        } else {
          state = 0;
        }

        return;
      }
    }
  }

  // -------------------------
  // Trial response
  // -------------------------
  if (state == 3 && visualShown) {
    int responseIndex = getResponseIndex(key);

    if (responseIndex != -1) {
      int rt = millis() - visualOnsetTime;

      currentTrial.userResponse = colorNames[responseIndex];
      currentTrial.reactionTime = rt;
      currentTrial.isCorrect = currentTrial.userResponse.equals(currentTrial.correctAnswer);

      printTrialResult(currentTrial);
      saveTrialResult(currentTrial);

      // Do not show Correct / Wrong feedback.
      // After response, directly go to next fixation or finish the experiment.
      currentTrialIndex++;

      if (currentTrialIndex >= trials.size()) {
        output.flush();
        output.close();
        state = 5;
      } else {
        state = 2;
        stateStartTime = millis();
      }
    }
  }
}


// ======================================================
// Keyboard released
// Hide mapping hint when H is released.
// ======================================================
void keyReleased() {
  if (key == 'h' || key == 'H') {
    mappingHintVisible = false;
  }
}


// ======================================================
// Prepare experiment after user finishes fruit mapping
// Return true if preparation succeeds.
// Return false if hard constraints cannot be satisfied.
// ======================================================
boolean prepareExperimentAfterMapping() {
  if (experimentPrepared) {
    return true;
  }

  preparationErrorMessage = "";

  trials.clear();
  currentTrialIndex = 0;

  generateTrials();

  boolean sequenceSucceeded = buildTrialSequenceWithConstraints();

  if (!sequenceSucceeded) {
    trials.clear();
    experimentPrepared = false;
    preparationErrorMessage = "Could not build a valid trial sequence. Please try again.";
    println(preparationErrorMessage);
    return false;
  }

  experimentPrepared = true;

  output = createWriter(outputFolderName + "/" + outputFileName);

  output.println(
    "trial_index," +
    "word_type," +
    "congruency," +
    "trial_category," +
    "display_sentence," +
    "word_meaning_color," +
    "ink_color," +
    "correct_answer," +
    "user_response," +
    "is_correct," +
    "reaction_time_ms," +
    "hint_used," +
    "fruit_mapping"
  );

  println("==================================");
  println("Fruit mapping completed.");
  printObjectMappingToConsole();
  println("Total trials: " + trials.size());
  println("Adjacent same correct answer exists: " + hasAdjacentSameCorrectColor());
  println("Adjacent same trial category exists: " + hasAdjacentSameTrialCategory());
  println("CSV file: " + outputFolderName + "/" + outputFileName);
  println("==================================");

  return true;
}


// ======================================================
// Convert pressed key to response index
// ======================================================
int getResponseIndex(char k) {
  k = Character.toLowerCase(k);

  for (int i = 0; i < responseKeys.length; i++) {
    if (k == responseKeys[i]) {
      return i;
    }
  }

  return -1;
}


// ======================================================
// Ask participant name
// ======================================================
String askParticipantName() {
  String name = JOptionPane.showInputDialog("Please enter participant name or ID:");

  if (name == null || name.trim().length() == 0) {
    name = "anonymous";
  }

  name = name.trim();
  return sanitizeFileName(name);
}


// ======================================================
// Clean participant name for file name
// ======================================================
String sanitizeFileName(String name) {
  String cleanName = "";

  for (int i = 0; i < name.length(); i++) {
    char c = name.charAt(i);

    if (Character.isLetterOrDigit(c) || c == '_' || c == '-') {
      cleanName += c;
    } else {
      cleanName += "_";
    }
  }

  return cleanName;
}


// ======================================================
// Prepare output folder for experiment results
// ======================================================
void prepareOutputFolder() {
  File outputFolder = new File(sketchPath(outputFolderName));

  if (!outputFolder.exists()) {
    outputFolder.mkdirs();
  }
}


// ======================================================
// Generate trials
//
// Design:
// word type: color_word / fruit_word
// congruency: match / mismatch
//
// 2 word types × 2 congruency types × 5 ink colors × 3 repetitions
// = 60 trials
// ======================================================
void generateTrials() {
  String[] wordTypes = {
    "color_word",
    "fruit_word"
  };

  String[] congruencies = {
    "match",
    "mismatch"
  };

  int repetitions = 3;

  for (String wordType : wordTypes) {
    for (String congruency : congruencies) {
      for (int colorIndex = 0; colorIndex < colorNames.length; colorIndex++) {
        for (int rep = 0; rep < repetitions; rep++) {
          Trial t = createTrial(wordType, congruency, colorIndex);
          trials.add(t);
        }
      }
    }
  }
}


// ======================================================
// Create one trial
// ======================================================
Trial createTrial(String wordType, String congruency, int correctColorIndex) {
  Trial t = new Trial();

  t.wordType = wordType;
  t.congruency = congruency;

  // Correct answer is always the actual ink color.
  t.correctAnswer = colorNames[correctColorIndex];
  t.inkColorIndex = correctColorIndex;
  t.inkColorValue = colorValues[correctColorIndex];

  int meaningColorIndex;

  if (congruency.equals("match")) {
    meaningColorIndex = correctColorIndex;
  } else {
    meaningColorIndex = getDifferentColorIndex(correctColorIndex);
  }

  t.wordMeaningColor = colorNames[meaningColorIndex];

  // -------------------------
  // Decide displayed sentence
  // -------------------------
  if (wordType.equals("color_word")) {
    // Example:
    // match:
    // display sentence = 紅色是什麼顏色
    // ink color = 紅
    //
    // mismatch:
    // display sentence = 綠色是什麼顏色
    // ink color = 紅
    t.displayWord = colorNames[meaningColorIndex] + "色"; // "是什麼顏色"

  } else if (wordType.equals("fruit_word")) {
    // Example:
    // If 蘋果 is mapped to 綠,
    // then displaying 蘋果是什麼顏色 means the semantic answer is 綠.
    int ObjectIndex = getObjectIndexByMappedColor(meaningColorIndex);
    t.displayWord = objectWords[ObjectIndex]; // "是什麼顏色"
  }

  return t;
}


// ======================================================
// Find the fruit that user mapped to a specific color
// ======================================================
int getObjectIndexByMappedColor(int colorIndex) {
  for (int i = 0; i < ObjectToColorIndex.length; i++) {
    if (ObjectToColorIndex[i] == colorIndex) {
      return i;
    }
  }

  return 0;
}


// ======================================================
// Get a color index different from the original one
// ======================================================
int getDifferentColorIndex(int originalIndex) {
  int newIndex = int(random(colorNames.length));

  while (newIndex == originalIndex) {
    newIndex = int(random(colorNames.length));
  }

  return newIndex;
}


// ======================================================
// Build trial sequence with constraints
//
// This replaces pure random shuffle.
//
// Hard constraints:
// 1. Adjacent trials must not have the same correct answer.
// 2. Adjacent trials must not have the same trial category.
//
// Method:
// - Keep a remaining trial pool.
// - Add one valid trial at a time.
// - If construction fails, restart.
// ======================================================
boolean buildTrialSequenceWithConstraints() {
  int maxAttempts = 3000;

  ArrayList<Trial> originalTrials = copyTrials(trials);

  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    ArrayList<Trial> remaining = copyTrials(originalTrials);
    ArrayList<Trial> ordered = new ArrayList<Trial>();

    // Randomize remaining pool first, so each attempt is different.
    shuffleTrialList(remaining);

    boolean failed = false;

    while (remaining.size() > 0) {
      int selectedIndex = selectNextValidTrialIndex(remaining, ordered);

      if (selectedIndex == -1) {
        failed = true;
        break;
      }

      Trial selectedTrial = remaining.get(selectedIndex);
      ordered.add(selectedTrial);
      remaining.remove(selectedIndex);
    }

    if (!failed && ordered.size() == originalTrials.size()) {
      trials = ordered;

      if (!hasAdjacentSameCorrectColor() && !hasAdjacentSameTrialCategory()) {
        println("Trial sequence constructed successfully.");
        println("Construction attempts used: " + (attempt + 1));
        return true;
      }
    }
  }

  println("Error: Could not construct a valid trial sequence.");
  return false;
}


// ======================================================
// Select next valid trial index from remaining trials
//
// A trial is valid if:
// - Its correct answer differs from the previous trial.
// - Its trial category differs from the previous trial.
//
// Among valid candidates, choose the one with the highest priority.
// The priority favors trials whose correct answer and category still have
// many remaining items, reducing the chance of getting stuck later.
// ======================================================
int selectNextValidTrialIndex(ArrayList<Trial> remaining, ArrayList<Trial> ordered) {
  Trial previousTrial = null;

  if (ordered.size() > 0) {
    previousTrial = ordered.get(ordered.size() - 1);
  }

  ArrayList<Integer> validIndices = new ArrayList<Integer>();

  for (int i = 0; i < remaining.size(); i++) {
    Trial candidate = remaining.get(i);

    if (previousTrial == null || isValidAfterPreviousTrial(candidate, previousTrial)) {
      validIndices.add(i);
    }
  }

  if (validIndices.size() == 0) {
    return -1;
  }

  int bestIndex = validIndices.get(0);
  float bestScore = -999999;

  for (int i = 0; i < validIndices.size(); i++) {
    int candidateIndex = validIndices.get(i);
    Trial candidate = remaining.get(candidateIndex);

    float score = getCandidatePriorityScore(candidate, remaining);

    // Add a small random value to avoid deterministic ordering.
    score += random(0, 0.5);

    if (score > bestScore) {
      bestScore = score;
      bestIndex = candidateIndex;
    }
  }

  return bestIndex;
}


// ======================================================
// Check whether candidate can follow previous trial
// ======================================================
boolean isValidAfterPreviousTrial(Trial candidate, Trial previousTrial) {
  if (candidate.correctAnswer.equals(previousTrial.correctAnswer)) {
    return false;
  }

  if (getTrialCategory(candidate).equals(getTrialCategory(previousTrial))) {
    return false;
  }

  return true;
}


// ======================================================
// Candidate priority score
//
// Higher score means the candidate is preferred.
//
// Reason:
// If many remaining trials have the same correct answer or category,
// we schedule that kind earlier to prevent it from accumulating at the end.
// ======================================================
float getCandidatePriorityScore(Trial candidate, ArrayList<Trial> remaining) {
  int sameCorrectAnswerCount = 0;
  int sameCategoryCount = 0;

  String candidateCategory = getTrialCategory(candidate);

  for (int i = 0; i < remaining.size(); i++) {
    Trial t = remaining.get(i);

    if (t.correctAnswer.equals(candidate.correctAnswer)) {
      sameCorrectAnswerCount++;
    }

    if (getTrialCategory(t).equals(candidateCategory)) {
      sameCategoryCount++;
    }
  }

  return sameCorrectAnswerCount + sameCategoryCount;
}


// ======================================================
// Shuffle a given trial list using Fisher-Yates shuffle
// ======================================================
void shuffleTrialList(ArrayList<Trial> list) {
  for (int i = list.size() - 1; i > 0; i--) {
    int j = int(random(i + 1));

    Trial temp = list.get(i);
    list.set(i, list.get(j));
    list.set(j, temp);
  }
}


// ======================================================
// Copy trial list
// ======================================================
ArrayList<Trial> copyTrials(ArrayList<Trial> source) {
  ArrayList<Trial> copied = new ArrayList<Trial>();

  for (int i = 0; i < source.size(); i++) {
    copied.add(source.get(i));
  }

  return copied;
}


// ======================================================
// Check whether two consecutive trials have the same answer color
// ======================================================
boolean hasAdjacentSameCorrectColor() {
  for (int i = 1; i < trials.size(); i++) {
    Trial previousTrial = trials.get(i - 1);
    Trial currentTrial = trials.get(i);

    if (previousTrial.correctAnswer.equals(currentTrial.correctAnswer)) {
      return true;
    }
  }

  return false;
}


// ======================================================
// Check whether two consecutive trials have the same trial category
// ======================================================
boolean hasAdjacentSameTrialCategory() {
  for (int i = 1; i < trials.size(); i++) {
    Trial previousTrial = trials.get(i - 1);
    Trial currentTrial = trials.get(i);

    if (getTrialCategory(previousTrial).equals(getTrialCategory(currentTrial))) {
      return true;
    }
  }

  return false;
}


// ======================================================
// Get trial category
// ======================================================
String getTrialCategory(Trial t) {
  return t.wordType + "_" + t.congruency;
}


// ======================================================
// Print fruit mapping to console
// ======================================================
void printObjectMappingToConsole() {
  println("Fruit-color mapping:");

  for (int i = 0; i < objectWords.length; i++) {
    println(objectWords[i] + " -> " + colorNames[ObjectToColorIndex[i]]);
  }
}


// ======================================================
// Convert fruit mapping to CSV-friendly string
// ======================================================
String getObjectMappingString() {
  String mapping = "";

  for (int i = 0; i < objectWords.length; i++) {
    mapping += objectWords[i] + "=" + colorNames[ObjectToColorIndex[i]];

    if (i < objectWords.length - 1) {
      mapping += "|";
    }
  }

  return mapping;
}


// ======================================================
// Print one trial result to Processing console
// ======================================================
void printTrialResult(Trial t) {
  println("==================================");
  println("Trial " + (currentTrialIndex + 1));
  println("Participant: " + participantName);
  println("Date: " + experimentDate);
  println("Word type: " + t.wordType);
  println("Congruency: " + t.congruency);
  println("Trial category: " + getTrialCategory(t));
  println("Display sentence: " + t.displayWord);
  println("Word meaning color: " + t.wordMeaningColor);
  println("Ink color / correct answer: " + t.correctAnswer);
  println("User response: " + t.userResponse);
  println("Correct: " + t.isCorrect);
  println("RT: " + t.reactionTime + " ms");
  println("Hint used: " + t.hintUsed);
}


// ======================================================
// Save one trial result to CSV
// ======================================================
void saveTrialResult(Trial t) {
  output.println(
    (currentTrialIndex + 1) + "," +
    t.wordType + "," +
    t.congruency + "," +
    getTrialCategory(t) + "," +
    t.displayWord + "," +
    t.wordMeaningColor + "," +
    t.correctAnswer + "," +
    t.correctAnswer + "," +
    t.userResponse + "," +
    t.isCorrect + "," +
    t.reactionTime + "," +
    t.hintUsed + "," +
    getObjectMappingString()
  );

  output.flush();
}


// ======================================================
// Trial class
// ======================================================
class Trial {
  String wordType;
  String congruency;

  String displayWord;
  String wordMeaningColor;

  int inkColorIndex;
  color inkColorValue;

  String correctAnswer;
  String userResponse;

  int reactionTime;
  boolean isCorrect;

  boolean hintUsed;
}
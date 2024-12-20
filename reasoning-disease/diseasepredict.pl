% Facts about diseases and their symptoms (with weight for each symptom)
disease(gastritis, [(swelling_of_jaw_or_cheek, 5), (mouth_ulcers, 2), (chapped_lips, 2)]).
disease(ulcer, [(bad_breath, 3), (vomiting, 3)]).
disease(stomach_tumor, [(stomach_pain, 3), (diarrhea, 4), (blood_and_mucus_in_stool, 5)]).
disease(stomach_cancer, [
    (severe_pain_and_tightness_above_the_stomach, 5),
    (frequent_burping_especially_when_hungry, 2),
    (difficulty_sleeping_due_to_stomach_pain, 4),
    (loss_of_appetite, 3)
]).
disease(gerd, [(constipation_more_than_three_days, 4), (nausea, 2), (burning_sensation_in_chest, 4)]).

% Function to ask the user about symptoms with yes/no answers
ask_symptom(Symptom) :-
    format('Do you experience ~w? (yes/no): ', [Symptom]),
    read(Answer),
    (Answer == yes -> assertz(experienced_symptom(Symptom)); fail).

% Function to calculate the total weight of the matched symptoms
calculate_symptom_weight([], _, 0).
calculate_symptom_weight([(Symptom, Weight)|Rest], KnownSymptoms, TotalWeight) :-
    (member(Symptom, KnownSymptoms) -> Weight1 is Weight; Weight1 is 0),
    calculate_symptom_weight(Rest, KnownSymptoms, RemainingWeight),
    TotalWeight is Weight1 + RemainingWeight.

% Function to diagnose based on the weight of symptoms
diagnosis_weight(Disease, Symptoms, KnownSymptoms, TotalWeight) :-
    calculate_symptom_weight(Symptoms, KnownSymptoms, TotalWeight),
    TotalWeight > 0, % Only display the disease if there are matching symptom weights
    format('Possible diagnosis: ~w (total matching symptom weight: ~2f)\n', [Disease, TotalWeight]).

% Start the diagnosis process
start_diagnosis :-
    retractall(experienced_symptom(_)), % Reset previous symptoms
    % Collect symptoms from the user
    findall(Symptom, (
        disease(_, SymptomList),
        member((Symptom, _), SymptomList),
        \+ experienced_symptom(Symptom),
        ask_symptom(Symptom)
    ), _),
    % Collect the symptoms that have been answered with yes
    findall(S, experienced_symptom(S), KnownSymptoms),
    % Process diagnosis based on weight
    findall((Disease, TotalWeight), (
        disease(Disease, SymptomList),
        diagnosis_weight(Disease, SymptomList, KnownSymptoms, TotalWeight)
    ), Results),
    % Determine the disease with the highest weight
    final_diagnosis(Results).

% Function to find all diseases with the highest weight
final_diagnosis([]) :-
    write('No disease matches the given symptoms.\n').
final_diagnosis(Results) :-
    sort(2, @>=, Results, SortedResults), % Sort by weight
    SortedResults = [(DiagnosisDisease, HighestWeight)|_], % Take the disease with the highest weight
    include(same_weight(HighestWeight), SortedResults, HighestWeightDiseases), % Take all diseases with the same highest weight
    format('Final diagnosis with the highest weight (~2f):\n', [HighestWeight]),
    forall(member((Disease, _), HighestWeightDiseases), format('- ~w\n', [Disease])).

% Predicate to compare weights
same_weight(Weight, (_, Weight)) :- !. % Compare if the weights are the same

% Start the diagnosis and print the results
run :-
    start_diagnosis,
    nl.

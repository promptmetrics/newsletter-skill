# Spam-Trigger Terms

> **Starting governance-friendly list.** To use a house suppressed-terms list, replace the contents of this file. The skill reads it at scan time, so editing this file requires no change to `SKILL.md`.

The spam scan (Step 6b) lowercases the assembled subject + preview text + stripped body text and flags any term below. **Scan is advisory** — flagged terms are warnings at Gate 2, not a hard block (context matters: "free" in "free trade" is not spam). The author acknowledges or revises.

The brief's `tone.must_avoid[]` is also matched — any `must_avoid` hit is flagged with higher salience.

## urgency
act now
limited time
deadline
urgent
hurry
last chance
while supplies last
ending soon
expires today
final hours
don't miss
don't wait

## hype
free
guarantee
amazing
incredible
revolutionary
game-changer
no-brainer
once in a lifetime
best ever
mind-blowing

## financial
no cost
save $
save money
make money
risk-free
100% free
winner
earn
cash bonus
double your
no investment

## subject-patterns (structural, not literal terms — flag if detected)
ALL CAPS SUBJECT (subject line is ≥60% uppercase letters)
EXCESSIVE PUNCTUATION (subject line has ≥3 exclamation marks or ≥2 consecutive !!!)
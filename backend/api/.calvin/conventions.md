## HARD RULES

Violations here cause guaranteed CI failures. Self-check before writing any file.

**Routing — nested namespace**
Inside a `namespace :x` block, `to:` must be relative — the outer namespace prefix
is applied automatically by Rails.
  CORRECT: namespace :signals { post :preferences, to: 'preferences#create' }
  WRONG:   namespace :signals { post :preferences, to: 'signals/preferences#create' }

**Model validations**
Do NOT add `validates :field, numericality:` or `validates :field, inclusion:`
for any field already covered by a contract rule.
The contract is the single validation source for API inputs.
Enum declarations (`enum :field, {...}`) are not validations — they are required and correct.

**Monad assertions in tests**
Any test class using `assert_pattern { result => Success }` MUST include
`include Dry::Monads[:result]` at the top of the class — not just the service.
Applies to service tests, contract tests, and any other non-controller test class.

**Fixtures**
Every new column added to a table requires updating `test/fixtures/<model_plural>.yml`.
Add the new attribute with an explicit value on every existing fixture row.
Never rely on database defaults — a missing enum column silently uses the wrong default.

**Scope discipline**
Only modify files that the task explicitly requires.
Do not refactor quoting style, whitespace, or syntax in files touched for other reasons.

---

## EXPLORATION (mandatory before writing any file)

Read these files before touching code:
1. app/controllers/api/v1/ — list the directory; check if a controller for this namespace exists already.
2. app/contracts/ — read one existing contract to learn the pattern in use.
3. app/models/<relevant_model>.rb — check existing validations and enums.
4. test/fixtures/<relevant>.yml — read it; you will update it.
5. test/test_helper.rb — check base classes and helpers once per session.
6. test/ — find and read one similar test file to learn the style.

## CONTRACTS

Canonical pattern (copy exactly):
  class FooContract < Dry::Validation::Contract
    params do
      required(:foo).hash do
        optional(:field).maybe(:integer, included_in?: 1..5)
        optional(:kind).maybe(:string)
      end
    end
    VALID_KINDS = %w[a b c].freeze
    rule(foo: :kind) do
      next unless value
      key.failure("must be a, b or c") unless VALID_KINDS.include?(value)
    end
  end

- Use inline predicates (included_in?, min_size?, etc.) before reaching for rule blocks.
- Define VALID_* constants in the contract; derive them from the model enum when possible:
    VALID_KINDS = MyModel.kinds.keys.freeze
- rule blocks only for logic that cannot be expressed as a predicate.
- Call from controller: result = FooContract.new.call(params.to_unsafe_h)

## CONTROLLERS

- Check the directory first. Create a new controller only if no suitable one exists.
- params.to_unsafe_h is the correct pattern when a dry-validation contract is present —
  the contract performs all filtering and type-checking. Do NOT use params.require/permit
  alongside a contract (it breaks nested hash coercion with dry-types).
- Never use render json: directly — use ApiResponse helpers (render_success, render_error, etc.).

## MODELS

- Do NOT add ActiveRecord validations for fields already validated by a contract.
- Enums use modern syntax only: enum :field, { value: integer }
- Always generate the migration together with the enum declaration.

## FIXTURES

- Read the existing fixture file before writing tests.
- Update fixture entries to include new columns (use explicit values, never rely on defaults).
- Add new named rows only if the existing ones are insufficient.
- Always set enum columns explicitly — missing enum = silent wrong default.

## TESTS

- Minimum per controller: happy path (200/201) + 401 (no token) + 422 (invalid params).
- Minimum per contract: one valid input + one failure per validated field.
- Minimum per model: enum values match schema + any new validation.
- Use auth_headers(users(:alice)) — never users(:alice).jwt (no such method).
- Use assert_pattern { result => Success } — never result.success? boolean.
- Every test class using assert_pattern must include Dry::Monads[:result] at the top.
- Never require 'minitest/mock'.
- Reuse fixture rows from the catalogue; invent new rows only when truly necessary.

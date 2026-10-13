# Upgrading PromptEngine

Run the upgrade generator after you bump the gem. It copies any migrations your app doesn't have yet, so you can run it on every upgrade:

```bash
bundle update prompt_engine
bin/rails generate prompt_engine:upgrade
bin/rails db:migrate
```

Then follow the section for each version you're moving past.

## Adding a new model

Most new models need no change at all. PromptEngine recognizes models by name and knows each one's provider and whether it takes temperature and effort. `Configuration::DEFAULT_MODEL_FAMILIES` holds the rules:

| Models | Provider | Temperature | Effort |
|---|---|---|---|
| `claude-opus-*`, `claude-sonnet-*`, `claude-haiku-*` from version 5 on, Claude Fable, Claude Mythos, Opus 4.7 and 4.8 | Anthropic | No | Yes |
| Opus 4.6, Sonnet 4.6 | Anthropic | Yes | Yes |
| Any other `claude-` model | Anthropic | Yes | No |
| `gpt-5` and later, the `o` series | OpenAI | No | No |
| Any other `gpt-` model | OpenAI | Yes | No |

Opus 4.5 takes effort, but only `low`, `medium` or `high`, so its rule sends none. Bedrock IDs such as `anthropic.claude-opus-5-5` match no rule.

To make a model selectable in the admin UI, list it in `config.models`. A model needs only a label there:

```ruby
config.models = {
  "claude-opus-5-5" => { label: "Claude Opus 5.5" },
  "gpt-5.5" => { label: "GPT-5.5" }
}
```

To list new models without editing the list, pass a callable that builds it from ruby_llm's registry. A model the filter matches then appears after the next `RubyLLM.models.refresh!`, or `Model.refresh!` in an app that stores the registry in its database. PromptEngine calls it a few times per request, so keep it cheap. This example keeps current Claude and GPT chat models and drops dated snapshots and specialized variants:

```ruby
config.models = lambda do
  RubyLLM.models.chat_models
    .select { |model| model.provider.in?(%w[anthropic openai]) }
    .select { |model| model.id.match?(/\A(claude-(opus|sonnet|haiku|fable)-\d|gpt-([5-9]|[1-9]\d))/) }
    .reject { |model| model.id.match?(/\d{4}-?\d{2}-?\d{2}|-(codex|pro|search|chat-latest)/) }
    .to_h { |model| [ model.id, { label: model.name } ] }
end
```

An entry can override what the name implies, key by key:

- `provider` is `"anthropic"` or `"openai"`. The playground uses it to pick the API key, and evaluations accept only `"openai"`.
- `supports_temperature: false` keeps temperature out of requests to models that reject it.
- `supports_effort: true` sends the prompt's effort as Anthropic's `output_config: { effort: }`. It applies only to Anthropic models.

To change the name rules, set `config.model_families` to an array of `[pattern, settings]` pairs, or `unshift` a pair onto the defaults to take precedence. The first matching pattern wins.

## 1.1.x to 1.2.0

### Database

One migration adds a nullable `effort` column to prompts, prompt versions and playground runs. Existing rows need no backfill.

### Model catalog

Each model's provider and capabilities now come from its name, as described in [Adding a new model](#adding-a-new-model). Entries in `config.models` can drop `provider`, and any key they keep overrides the name rules. A model that matches no rule and has no `provider` behaves as in 1.1.x: it takes temperature, gets no effort, and the playground rejects it as unknown.

`config.models` can also be a callable that returns the hash.

A stored setting the model doesn't accept stays on the prompt but isn't sent, and the prompt page marks it "not sent to this model". Switching the model in the form clears the fields the new model doesn't accept.

### ruby_llm

PromptEngine now requires `ruby_llm ~> 1.16`, the version its playground and `to_ruby_llm_chat` are tested against.

PromptEngine no longer loads ruby_llm when it loads. If your app calls `RubyLLM` itself, for example in an initializer, add `ruby_llm` to your Gemfile or require it yourself.

### RenderedPrompt

- **No default model.** `to_ruby_llm_params` and `to_openai_params` no longer fall back to `"gpt-4"` when a prompt has no model. They leave out the `model` key instead.
- **OpenAI token limit.** For a model whose catalog provider is `"openai"`, `to_ruby_llm_params` and `to_openai_params` send `max_tokens` as `max_completion_tokens`. OpenAI's reasoning models reject `max_tokens`.
- **Passing params to `with_params`.** If you pass `to_ruby_llm_params` to `RubyLLM::Chat#with_params`, drop `:messages` and `:model` first. Otherwise they replace the chat's own messages and model. `to_ruby_llm_chat` does this for you.
- **`execute_with`.** It takes the `RubyLLM` module or a `RubyLLM::Context` and returns the reply. It raises `ArgumentError` for a ruby_llm provider object or an Anthropic SDK client. Neither worked before: their `chat` methods don't accept the arguments it passed.
- **`to_ruby_llm_chat`.** This new method returns a `RubyLLM::Chat` with the system message and settings applied. Use it when you need tools or a schema before calling `ask`.

### Rendering

`effort` is a render option, like `model` and `temperature`. `PromptEngine.render(slug, variables, options:)` keeps the two hashes apart, so a template variable named `{{effort}}` still renders as a variable.

If you call `Prompt#render` directly with keyword arguments, an `effort:` keyword is now an override, and a `variables:` keyword holds the variables hash. To pass a template variable named `effort` or `variables`, use `prompt.render(variables: { effort: "..." })`.

### Evaluations

Evaluations run on OpenAI's Evals API. A run now starts only when the prompt's model is in the catalog with provider `"openai"`. Otherwise, the page explains why instead of sending the request.

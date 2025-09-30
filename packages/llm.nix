# `llm` is a terminal program which provides access to LLMs.
# https://pypi.org/project/llm/
#
# This file is intended to be used with `callPackage`.
{ llm }:

llm.withPlugins {
  # llm-anthropic supports Anthropic’s Claude 4 family and beyond.
  # https://github.com/simonw/llm-anthropic
  llm-anthropic = true;

  # llm-gemini adds support for Google’s Gemini models.
  # https://github.com/simonw/llm-gemini
  llm-gemini = true;

  # llm-grok by Benedikt Hiepler providing access to Grok model using the xAI API Grok.
  # https://github.com/Hiepler/llm-grok
  llm-grok = true;

  # LLM plugin for OpenAI models. This plugin is a preview.
  # LLM currently ships with OpenAI models as part of its default collection, implemented using the
  # Chat Completions API. This plugin implements those same models using the new Responses API.
  # https://github.com/simonw/llm-openai-plugin
  llm-openai-plugin = true;

  # Use LLM to generate and execute commands in your shell
  # https://github.com/simonw/llm-cmd
  llm-cmd = true;

  # JavaScript execution as a tool for LLM
  # https://github.com/simonw/llm-tools-quickjs
  llm-tools-quickjs = true;

  # Make simple_eval available as an LLM tool
  # https://github.com/danthedeckie/simpleeval
  # https://github.com/simonw/llm-tools-simpleeval
  llm-tools-simpleeval = true;

  # LLM tools for running queries against SQLite
  # https://github.com/simonw/llm-tools-sqlite
  llm-tools-sqlite = true;

  # Load GitHub repository contents as fragments
  # https://github.com/simonw/llm-fragments-github
  llm-fragments-github = true;
}

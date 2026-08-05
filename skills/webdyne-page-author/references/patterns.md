# WebDyne Page Patterns

## Simple Handler Page

```html
<start_html title="Greeting" h1>

<start_form>
<textfield name="name" label="Name">
<submit value="Say hello">
<end_form>

<perl handler="greeting">
<p>Hello ${name}</p>
</perl>

__PERL__

sub greeting {
    my $self = shift;
    return \undef unless $_{'name'};
    return $self->render(name => $_{'name'});
}
```

## Form With Stateful Helpers

```html
<start_html title="Survey" h1>

<start_form>
<textfield name="name" label="Name">
<popup_menu
  name="color"
  values="@{qw(red green blue)}"
  label="Favorite color">
<checkbox_group
  name="features"
  values="@{qw(speed docs examples)}"
  defaults="@{qw(docs)}">
<submit value="Submit">
<end_form>

<perl handler="summary">
<p>Name: ${name}</p>
<p>Color: ${color}</p>
<p>Features: ${features}</p>
</perl>

__PERL__

sub summary {
    my $self = shift;
    return \undef unless $self->CGI->param;

    my $features = join(', ', $self->CGI->param('features'));
    return $self->render(
        name     => $_{'name'} || '',
        color    => $_{'color'} || '',
        features => $features,
    );
}
```

## Conditional Blocks

Use `<block>` to keep dynamic output as markup instead of string-building in Perl.

```html
<start_html title="Quiz">

<start_form>
2 + 2 = <textfield name="sum">
<submit value="Check">
<end_form>

<perl handler="check">
<block name="pass">
<p>Correct: +{sum}</p>
</block>

<block name="fail">
<p>Sorry, +{sum} is not correct.</p>
</block>
</perl>

__PERL__

sub check {
    my $self = shift;
    return \undef unless length($_{'sum'} || '');

    if (($_{'sum'} + 0) == 4) {
        $self->render_block('pass');
    }
    else {
        $self->render_block('fail');
    }

    return $self->render();
}
```

`render_block` can pass substitutions:

```perl
$self->render_block('row', name => $name, count => $count);
```

## Includes

Include whole files:

```html
<include file="./nav.html">
```

Include only parts of another PSP/HTML file:

```html
<include head file="./layout.psp">
<include body file="./layout.psp">
<include block="footer" file="./layout.psp">
```

Wrap plain included text:

```html
<include file="/etc/protocols" wrap="pre">
```

## JSON Data For JavaScript

Use `<json>` when the page needs server data for client-side JavaScript.

```html
<start_html title="Chart" script="https://cdn.jsdelivr.net/npm/chart.js">

<json id="chart-data" handler="chart_data"/>
<canvas id="chart"></canvas>

<script>
const chartData = JSON.parse(document.getElementById("chart-data").textContent);
new Chart(document.getElementById("chart"), {
  type: "bar",
  data: chartData
});
</script>

__PERL__

sub chart_data {
    return {
        labels   => [qw(Jan Feb Mar Apr)],
        datasets => [{
            label => 'Sales',
            data  => [120, 150, 180, 100],
        }],
    };
}
```

For JSON booleans, use `JSON::true` and `JSON::false`.

## API Routes

Use `<api>` for JSON endpoints. Pattern values use Router::Simple-style routes.

```html
<api handler="uppercase" pattern="/api/uppercase/{user}/:id"/>

__PERL__

sub uppercase {
    my ($self, $match) = @_;
    my ($user, $id) = @{$match}{qw(user id)};
    return {
        user => uc($user),
        id   => $id,
    };
}
```

## HTMX

Full page loading htmx:

```html
<start_html htmx title="Current Time">

<button hx-get="time.psp" hx-target="#time-container" hx-swap="innerHTML">
  Get Time
</button>

<div id="time-container">
  <em>Time not loaded.</em>
</div>
```

Fragment endpoint:

```html
<start_html>
<htmx>Server local time: <? localtime() ?></htmx>
```

Use `<htmx force="+{debug}">...</htmx>` to show fragment output during normal requests while debugging.

## Sessions

Use `WebDyne::Session` in the `__PERL__` section. It adds the session handler chain and exposes `session_id()`.

```html
<start_html title="Session">
Session ID: !{! shift()->session_id() !}

__PERL__

use WebDyne::Session;
1;
```

## Static Pages

For a whole static page:

```html
<start_html static title="Static Page">
Generated once: <? localtime() ?>
```

Or use the module:

```html
<start_html title="Static Page">
<perl handler="mtime">Last Modified: ${mtime}</perl>

__PERL__

use WebDyne::Static;

sub mtime {
    my $self = shift;
    my $file = $self->request->filename;
    return $self->render(mtime => scalar localtime((stat($file))[9]));
}
```

## External Perl Modules

For larger projects, keep `.psp` files mostly markup and call app modules:

```html
<start_html title="Account">
<perl handler="MyApp::Page::account"/>
```

If the module is not otherwise loaded, a fully qualified handler normally triggers a require for the module part.

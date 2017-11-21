---
categories:
- android
- development
- textview
comments: true
date: 2014-03-06T19:13:17Z
title: Using custom font in Android TextView
url: /2014/03/06/customizing-font-in-android-textview/
---

Today I want to share with you custom [TextView] which allows to set font to be used in xml layout.

First, we need to declare our custom styleable

attrs.xml: 

```xml 

<?xml version="1.0" encoding="utf-8"?>
<resources>

    <declare-styleable name="TypefaceTextView">
        <attr name="typeface" format="string"/>
    </declare-styleable>

</resources>

```

Then we need to create subclass of `TextView` which will use custom attribute.

TypefaceTextView: 

```java 
public class TypefaceTextView extends TextView {

    public TypefaceTextView(Context context) {
        this(context, null);
    }

    public TypefaceTextView(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public TypefaceTextView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);

        TypedArray ta = context.getTheme().obtainStyledAttributes(attrs, R.styleable.TypefaceTextView, 0, 0);
        try {
            String font = ta.getString(R.styleable.TypefaceTextView_typeface);
            if (null == font) {
                font = context.getString(R.string.default_font_name);
            }
            Typeface typeface = TypefaceCache.getTypeface(context, font);
            if (null != typeface) {
                setTypeface(typeface);
            }

        } finally {
            ta.recycle();
        }
    }
}
```

Also, above class allows to use default custom font, all is needed is to define its name in `strings.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="default_font_name" translatable="false">custom.ttf</string>
</resources>

```

Due to the [bug in Android][issue9904] we have to cache all created typefaces in cache:

TypefaceCache: 

```java

public class TypefaceCache {

    private static final Map<String, Typeface> CACHE = new HashMap<String, Typeface>();

    public static Typeface getTypeface(Context context, String font) {
        if (null == font) {
            return null;
        }
        Typeface typeface = CACHE.get(font);
        if (null == typeface) {

            typeface = Typeface.createFromAsset(context.getAssets(), font);
            CACHE.put(font, typeface);
        }
        return typeface;
    }
}
```

Basically, that's it. In order to use it is required to put TTF font in the `assets` folder and reference the font:

Example usage: 

```xml 
<?xml version="1.0" encoding="utf-8"?>
<com.example.android.widget.TypefaceTextView 
    xmlns:a="http://schemas.android.com/apk/res/android"
    xmlns:custom="http://schemas.android.com/apk/res-auto"
    a:layout_width="match_parent"
    custom:typeface="custom-font.ttf"/>
```

And the last use case it to set custom font for the actionbar title. In this case we can implement custom [`android.text.style.CharacterStyle`][CharacterStyle]

TypefaceSpan: 

```java 
public class TypefaceSpan extends MetricAffectingSpan {

    private Typeface mTypeface;

    /**
     * Load the {@link Typeface} and apply to a {@link Spannable}.
     */
    public TypefaceSpan(Context context, String typefaceName) {
        mTypeface = TypefaceCache.getTypeface(context, typefaceName);
    }

    @Override
    public void updateMeasureState(TextPaint p) {
        p.setTypeface(mTypeface);

        // Note: This flag is required for proper typeface rendering
        p.setFlags(p.getFlags() | Paint.SUBPIXEL_TEXT_FLAG);
    }

    @Override
    public void updateDrawState(TextPaint tp) {
        tp.setTypeface(mTypeface);

        // Note: This flag is required for proper typeface rendering
        tp.setFlags(tp.getFlags() | Paint.SUBPIXEL_TEXT_FLAG);
    }
}
```

Then we can set actionbar title using the following code:

``` java

public static void setActionBarTitle(Activity context, CharSequence title) {
    SpannableString s = new SpannableString(title);
    s.setSpan(new TypefaceSpan(context, context.getString(R.string.default_font_name)), 0, s.length(),
        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
        context.getActionBar().setTitle(s);
    }
}

```

### Additional information

1. [Creating a View Class | Android Developers](http://developer.android.com/training/custom-views/#create-view.html)

[issue9904]: https://code.google.com/p/android/issues/detail?id=9904
[CharacterStyle]: http://developer.android.com/reference/android/text/style/CharacterStyle.html
[TextView]: http://developer.android.com/reference/android/widget/TextView.html

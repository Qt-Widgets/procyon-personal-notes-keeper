#include "TextEditHelpers.h"

#include <QTextBlock>

//------------------------------------------------------------------------------
//                                  TextFormat
//------------------------------------------------------------------------------

QTextCharFormat TextFormat::get() const
{
    QTextCharFormat f;
    if (!_fontFamily.isEmpty())
        f.setFontFamily(_fontFamily);
    if (!_colorName.isEmpty())
        f.setForeground(QColor(_colorName));
    if (_bold)
        f.setFontWeight(QFont::Bold);
    f.setFontItalic(_italic);
    f.setFontUnderline(_underline);
    f.setAnchor(_anchor);
    f.setFontStrikeOut(_strikeOut);
    if (_spellError)
    {
        f.setUnderlineColor("red");
        f.setUnderlineStyle(QTextCharFormat::SpellCheckUnderline);
    }
    if (!_backColorName.isEmpty())
        f.setBackground(QColor(_backColorName));
    return f;
}

//------------------------------------------------------------------------------
//                                TextEditHelpers
//------------------------------------------------------------------------------

namespace TextEditHelpers
{

// Hyperlink made via syntax highlighter doesn't create some 'top level' anchor,
// so `anchorAt` returns nothing, we have to enumerate styles to find out a href.
QString hyperlinkAt(const QTextCursor& cursor)
{
    int cursorPos = cursor.positionInBlock() - (cursor.position() - cursor.anchor());
    for (auto format : cursor.block().layout()->formats())
        if (format.format.isAnchor() &&
            cursorPos >= format.start &&
            cursorPos < format.start + format.length)
        {
            auto href = format.format.anchorHref();
            if (not href.isEmpty()) return href;
        }
    return QString();
}

} // namespace TextEditHelpers

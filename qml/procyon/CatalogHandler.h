#ifndef CATALOGHANDLER_H
#define CATALOGHANDLER_H

#include <QAbstractItemModel>
#include <QFont>
#include <QObject>
#include <QUrl>

class Catalog;
class CatalogModel;

class CatalogHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isOpened READ isOpened NOTIFY isOpenedChanged)
    Q_PROPERTY(QString filePath READ filePath NOTIFY fileNameChanged)
    Q_PROPERTY(QString fileName READ fileName NOTIFY fileNameChanged)
    Q_PROPERTY(QString memoCount READ memoCount NOTIFY memoCountChanged)
    Q_PROPERTY(QAbstractItemModel* model READ catalogModel NOTIFY catalogModelChanged)
    Q_PROPERTY(const QStringList& recentFilesModel READ recentFiles NOTIFY recentFilesChanged)
    // TODO: can't read recentFilesModel.count or recentFilesModel.empty in qml, so use this property
    Q_PROPERTY(bool hasRecentFiles READ hasRecentFiles NOTIFY recentFilesChanged)
    Q_PROPERTY(QString recentFile READ recentFile NOTIFY recentFilesChanged)
    Q_PROPERTY(QFont memoFont READ memoFont WRITE setMemoFont NOTIFY memoFontChanged)
    Q_PROPERTY(bool memoWordWrap READ memoWordWrap WRITE setMemoWordWrap NOTIFY memoWordWrapChanged)

public:
    explicit CatalogHandler(QObject *parent = nullptr);
    ~CatalogHandler();

    bool isOpened() const { return _catalog; }
    QString filePath() const;
    QString fileName() const;
    QString memoCount() const;
    QAbstractItemModel* catalogModel() const;
    const QStringList& recentFiles() const { return _recentFiles; }
    bool hasRecentFiles() const { return !_recentFiles.empty(); }
    QString recentFile() const { return _recentFile; }
    QFont memoFont() const { return _memoFont; }
    void setMemoFont(const QFont& font);
    bool memoWordWrap() const { return _memoWordWrap; }
    void setMemoWordWrap(bool on);

signals:
    void error(const QString &message) const;
    void info(const QString &message) const;
    void fileNameChanged() const;
    void memoCountChanged() const;
    void catalogModelChanged() const;
    void recentFilesChanged() const;
    void isOpenedChanged() const;
    void memoFontChanged() const;
    void memoWordWrapChanged() const;
    void memoChanged(const QMap<QString, QVariant>& memoData) const;
    void folderRenamed(int folderId) const;
    void memoCreated(int memoId) const;
    void memoDeleted(int memoId) const;

    void needExpandIndex(const QModelIndex& index) const;
    void needSelectIndex(const QModelIndex& index) const;

public slots:
    void loadSettings();
    void saveSettings();

    void newCatalog(const QUrl &fileUrl);
    bool sameFile(const QString &fileName) const;
    bool sameUrl(const QUrl &fileUrl) const;
    void loadCatalogFile(const QString &fileName);
    void loadCatalogUrl(const QUrl &fileUrl);
    void closeCatalog();

    QMap<QString, QVariant> getStoredSession();
    void storeSession(const QMap<QString, QVariant>& session);

    void deleteInvalidMruItems();
    void deleteAllMruItems();

    bool isValidId(int memoId) const;

    QMap<QString, QVariant> getMemoInfo(int memoId);
    QString getMemoText(int memoId) const;
    QString saveMemo(const QMap<QString, QVariant>& data);
    void createMemo(int folderId);
    void deleteMemo(int memoId);

    QMap<QString, QVariant> getFolderInfo(int folderId);
    QString renameFolder(int folderId, const QString& newTitle);
    QString createFolder(int parentFolderId, const QString& title);
    void deleteFolder(int folderId);

private:
    Catalog *_catalog = nullptr;
    CatalogModel *_catalogModel = nullptr;
    QStringList _recentFiles;
    QString _recentFile;
    QFont _memoFont;
    bool _memoWordWrap;

    void catalogOpened(Catalog *catalog);
    void addToRecent(const QString &fileName);
    QString urlToFileName(const QUrl &fileUrl) const;
};

#endif // CATALOGHANDLER_H

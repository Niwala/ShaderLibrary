using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.SceneManagement;
using UnityEditor.SceneManagement;


public class Library : ScriptableObject
{
    public const int projectVersion = 0;
    public const string gitDownloadUrl = "https://raw.githubusercontent.com//Niwala/Challenges/main";

    [System.NonSerialized]
    public string search;

    [MenuItem("Challenges/Library")]
    public static void Open()
    {
        Open("");
    }

    public static void Open(string search)
    {
        Library instance = ScriptableObject.CreateInstance<Library>();
        instance.search = search;
        Selection.activeObject = instance;
    }

    [InitializeOnLoadMethod]
    private static void RegisterDelayOpen()
    {
        if (EditorPrefs.GetBool("Updater_AutoOpen", false))
            EditorApplication.update += DelayOpen;
        Selection.selectionChanged += OnSelectionChange;
    }

    private static void DelayOpen()
    {
        EditorApplication.update -= DelayOpen;
        Open();
    }

    private static void OnSelectionChange()
    {
        EditorPrefs.SetBool("Updater_AutoOpen", Selection.activeObject is Library);
    }
}

[CustomEditor(typeof(Library))]
public class Library_Editor : Editor
{
    private static List<LibraryElement> elements = new List<LibraryElement>();
    private static List<LibraryElement> filteredElements = new List<LibraryElement>();

    //Styles
    private GUIStyle titleStyle;
    private GUIStyle descriptionStyle;
    private GUIContent validIcon;
    private GUIContent minorUpdateIcon;
    private GUIContent majorUpdateIcon;
    private GUIContent newIcon;
    private GUIContent depreciatedIcon;
    private GUIContent refreshIcon;
    private bool stylesLoaded;


    private void OnEnable()
    {
        LoadAllElements();
    }

    private void OnDisable()
    {
        DestroyImmediate(target);
    }

    private void LoadStyles()
    {
        titleStyle = new GUIStyle(EditorStyles.largeLabel);
        titleStyle.fontSize = 20;

        descriptionStyle = new GUIStyle(EditorStyles.largeLabel);
        descriptionStyle.wordWrap = true;

        validIcon = EditorGUIUtility.IconContent("d_Progress@2x");
        validIcon.tooltip = "All good";
        minorUpdateIcon = EditorGUIUtility.IconContent("d_console.warnicon.inactive.sml@2x");
        minorUpdateIcon.tooltip = "There is a minor update available. It should not affect your data";
        majorUpdateIcon = EditorGUIUtility.IconContent("d_console.warnicon");
        majorUpdateIcon.tooltip = "There is a major update available. It may affect your data";
        newIcon = EditorGUIUtility.IconContent("Download-Available@2x");
        newIcon.tooltip = "New challenge!";
        depreciatedIcon = EditorGUIUtility.IconContent("d_console.erroricon");
        depreciatedIcon.tooltip = "This challenge is deprecated, it will not be updated anymore.";
        refreshIcon = EditorGUIUtility.IconContent("Refresh@2x");
        stylesLoaded = true;
    }

    public override bool UseDefaultMargins()
    { return false; }

    protected override void OnHeaderGUI()
    {
        GUILayout.BeginHorizontal(EditorStyles.toolbar);
        Library library = target as Library;

        //Search bar
        Rect rect = GUILayoutUtility.GetRect(Screen.width - 46, EditorGUIUtility.singleLineHeight);
        rect.Set(rect.x + 4, rect.y + 2, rect.width, rect.height);
        string newSearch = EditorGUI.TextField(rect, library.search, EditorStyles.toolbarSearchField);
        if (newSearch != library.search)
        {
            library.search = newSearch;
            UpdateFilteredElements();
        }


        GUILayout.FlexibleSpace();


        //Settings
        rect = GUILayoutUtility.GetRect(22, EditorGUIUtility.singleLineHeight);
        if (GUI.Button(rect, EditorGUIUtility.IconContent("d_icon dropdown"), EditorStyles.toolbarButton))
        {
            GenericMenu menu = new GenericMenu();
            menu.AddItem(new GUIContent("Refresh"), false, () => { elements.Clear(); LoadAllElements(); });


            //if (Event.current.shift)
            //    menu.AddItem(new GUIContent("Generate Index File"), false, () => { GenerateIndexFile(); });
            //if (Event.current.shift)
            //    menu.AddItem(new GUIContent("Export all challenges"), false, () => { GenerateIndexFile(); ExportAllChallenges(); });

            menu.AddSeparator("");
            menu.DropDown(rect);
        }
        GUILayout.EndHorizontal();
    }

    public override void OnInspectorGUI()
    {
        if (!stylesLoaded)
            LoadStyles();

        Rect rect = GUILayoutUtility.GetRect(1, Screen.height, GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true));
        int column = Mathf.FloorToInt(Screen.width / 150.0f);
        float size = rect.width / (float)column;

        //EditorGUI.DrawRect(ra, Color.black);

        //GUILayout.Label("fds");

        
        int columnID = 0;
        int rowID = 0;
        for (int i = 0; i < filteredElements.Count; i++)
        {
            Rect r = new Rect(rect.x + columnID * size, rect.y + rowID * size, size, size);
            DrawElementGUI(r, filteredElements[i]);
            columnID++;
            if (columnID >= column)
            {
                columnID = 0;
                rowID ++;
            }
        }

        Repaint();
    }

    private void DrawElementGUI(Rect rect, LibraryElement element)
    {
        string name = element.nodeName;

        rect.Set(rect.x + 5, rect.y + 5, rect.width - 10, rect.height - 10);

        Rect btnRect = new Rect(rect.x + rect.width - 40, rect.y + 5, 36, 36);
        int openMenu = GUI.Button(btnRect, "", GUIStyle.none) ? 1 : 0;

        bool focus = rect.Contains(Event.current.mousePosition);
        if (focus)
        {
            GUI.color = new Color(0.3f, 0.8f, 1.6f, 1.0f);
            GUI.Box(rect, "", EditorStyles.helpBox);
            GUI.color = Color.white;
        }
        EditorGUIUtility.AddCursorRect(btnRect, MouseCursor.Link);

        if (GUI.Button(rect, "", EditorStyles.helpBox))
        {
            if (Event.current.button == 0)
            {
                Selection.activeObject = element;
            }
        }

        //Preview
        if (element.material != null)
        {
            float time = (float)(EditorApplication.timeSinceStartup % 1000.0);
            element.material.SetFloat("_CustomTime", time);
            element.material.SetFloat("_Ratio", 1.0f);
            element.material.SetInt("_Function", 0);
            Rect previewRect = new Rect(rect.x + 2, rect.y + 2, rect.width - 4, rect.height - 4);
            EditorGUI.DrawPreviewTexture(previewRect, Texture2D.whiteTexture, element.material);
        }


        Rect titleRect = new Rect(rect.x + 5, rect.y + 5, rect.width - 10, 24);
        GUI.Label(titleRect, ObjectNames.NicifyVariableName(name), titleStyle);

        Rect descriptionRect = new Rect(rect.x + 15, rect.y + 35, rect.width - rect.height * 1.5f, rect.height - 35);
        GUI.Label(descriptionRect, element.description, descriptionStyle);
    }

    private void LoadAllElements()
    {
        elements.Clear();
        string[] guids = AssetDatabase.FindAssets("t:LibraryElement");

        foreach (string guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            LibraryElement element = AssetDatabase.LoadAssetAtPath<LibraryElement>(path);
            if (element != null)
                elements.Add(element);
        }

        UpdateFilteredElements();
    }

    private void UpdateFilteredElements()
    {
        Library library = target as Library;
        filteredElements.Clear();

        for (int i = 0; i < elements.Count; i++)
        {
            //Search filter
            if (!string.IsNullOrEmpty(library.search))
            {
                Match match = Regex.Match(elements[i].tags, library.search, RegexOptions.IgnoreCase | RegexOptions.IgnorePatternWhitespace);
                if (!match.Success)
                {
                    match = Regex.Match(elements[i].nodeName, library.search, RegexOptions.IgnoreCase | RegexOptions.IgnorePatternWhitespace);
                    if (!match.Success)
                        continue;
                }
            }

            filteredElements.Add(elements[i]);
        }

        Repaint();
    }
}
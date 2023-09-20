using System.Collections;
using System.Linq;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor;
using UnityEditor.UIElements;
using System.Runtime.CompilerServices;

namespace Challenges
{
    [CustomEditor(typeof(Library))]
    public class LibraryEditor : Editor
    {
        #region Static

        private static List<LibraryElement> elements = new List<LibraryElement>();

        [MenuItem("Challenges/Library &L")]
        public static void Open()
        {
            OpenWithSearch("");
        }

        public static void OpenWithSearch(string search)
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
        #endregion

        private const string documentRelativePath = "UI\\LibraryDocument.uxml";
        private const string sectionRelativePath = "UI\\SectionDocument.uxml";
        private const string elementRelativePath = "UI\\ElementDocument.uxml";
        private static VisualTreeAsset document;
        private static VisualTreeAsset sectionDocument;
        private static VisualTreeAsset elementDocument;
        private VisualElement root;
        private VisualElement list;
        private Dictionary<string, VisualElement> sections = new Dictionary<string, VisualElement>();
        private Dictionary<LibraryElement, VisualElement> visualElements = new Dictionary<LibraryElement, VisualElement>();

        private void OnEnable()
        {
            LoadAllElements();
        }

        private void OnDisable()
        {
            DestroyImmediate(target);
        }

        public override VisualElement CreateInspectorGUI()
        {
            //Load document
            if (document == null)
            {
                string filePath = GetFilePath();
                filePath = filePath.Remove(0, Application.dataPath.Length - 6);
                document = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(filePath.Replace($"{nameof(LibraryEditor)}.cs", documentRelativePath));
                sectionDocument = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(filePath.Replace($"{nameof(LibraryEditor)}.cs", sectionRelativePath));
                elementDocument = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(filePath.Replace($"{nameof(LibraryEditor)}.cs", elementRelativePath));
            }

            //Build document
            root = document.CloneTree();
            list = root.Q<VisualElement>("Content");

            //Search bar
            ToolbarSearchField searchField = root.Q<ToolbarSearchField>();
            searchField.SetValueWithoutNotify(((Library)target).search);
            searchField.RegisterValueChangedCallback(OnSearchChange);

            //Build list
            sections.Clear();
            visualElements.Clear();
            LoadAllElements();

            foreach (var element in elements)
            {
                string section = "Miscs";

                if (!string.IsNullOrEmpty(element.breadcrumbs))
                    section = element.breadcrumbs.Split(',')[0];

                if (!sections.ContainsKey(section))
                    AddSection(section);

                AddElementToSection(section, element);
            }

            void AddSection(string section)
            {
                VisualElement sectionElement = sectionDocument.CloneTree();
                sectionElement.Q<TextElement>("Label").text = section;
                sections.Add(section, sectionElement.Q<VisualElement>("Content"));
                list.Add(sectionElement);
            }

            void AddElementToSection(string section, LibraryElement element)
            {
                VisualElement visualElement = elementDocument.CloneTree();
                visualElement.Q<TextElement>("Label").text = element.nodeName;
                visualElement.Q<IMGUIContainer>("Preview").onGUIHandler += () => OnDrawElementGUI(element, visualElement);
                visualElements.Add(element, visualElement);
                visualElement.style.marginBottom = visualElement.style.marginLeft = visualElement.style.marginRight = visualElement.style.marginTop = 5;
                SetElementSize(visualElement, 150);
                sections[section].Add(visualElement);
            }

            FilterElements();

            return root;
        }

        private void SetElementSize(VisualElement parent, float size)
        {
            parent.style.width = parent.style.height = parent[0].style.width = parent[0].style.height = size;
        }

        protected override void OnHeaderGUI() { }

        private void OnDrawElementGUI(LibraryElement element, VisualElement visualElement)
        {
            Rect rect = visualElement.contentRect;
            rect.Set(rect.x - 2, rect.y - 2, rect.width + 2, rect.height + 2); //Align Legacy GUI - Toolkit

            bool focus = rect.Contains(Event.current.mousePosition);
            if (focus)
                EditorGUI.DrawRect(rect, new Color(0.3f, 0.8f, 1.6f, 0.2f));
            EditorGUIUtility.AddCursorRect(rect, MouseCursor.Link);

            if (GUI.Button(rect, "", GUIStyle.none) && Event.current.button == 0)
                Selection.activeObject = element;

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

            root.MarkDirtyRepaint();
        }

        public string GetFilePath([CallerFilePath] string sourceFilePath = "")
        {
            return sourceFilePath;
        }

        public override bool UseDefaultMargins()
        { return false; }

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
        }

        private void OnSearchChange(ChangeEvent<string> e)
        {
            Library library = (Library)target;
            library.search = e.newValue;
            FilterElements();
        }

        private void FilterElements()
        {
            Library library = target as Library;

            //Update element visibility
            for (int i = 0; i < elements.Count; i++)
            {
                bool visible = false;

                //Search filter
                if (!string.IsNullOrEmpty(library.search))
                {
                    Match match = Regex.Match(elements[i].tags + " " + elements[i].breadcrumbs, library.search, RegexOptions.IgnoreCase | RegexOptions.IgnorePatternWhitespace);
                    if (match.Success)
                    {
                        visible = true;
                    }
                    else
                    {
                        match = Regex.Match(elements[i].nodeName, library.search, RegexOptions.IgnoreCase | RegexOptions.IgnorePatternWhitespace);
                        if (match.Success)
                            visible = true;
                    }
                }
                else
                {
                    visible = true;
                }

                visualElements[elements[i]].style.display = visible ? DisplayStyle.Flex : DisplayStyle.None;
            }

            //Update sections visibility
            foreach (var item in sections)
            {
                bool visible = false;
                for (int i = 0; i < item.Value.childCount; i++)
                {
                    if (item.Value[i].style.display == DisplayStyle.Flex)
                    {
                        visible = true;
                        continue;
                    }
                }

                item.Value.parent.style.display = visible ? DisplayStyle.Flex : DisplayStyle.None;
            }
        }
    }
}
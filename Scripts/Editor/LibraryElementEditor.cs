using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor;
using UnityEditor.UIElements;
using System.Runtime.CompilerServices;
using System.Text.RegularExpressions;
using Debug = UnityEngine.Debug;
using Cursor = UnityEngine.UIElements.Cursor;

[CustomEditor(typeof(LibraryElement))]
public class LibraryElementEditor : Editor
{
    private const string documentRelativePath = "UI\\LibraryElementDocument.uxml";
    private static VisualTreeAsset document;
    private IMGUIContainer preview;
    private IMGUIContainer backPreview;

    private const string functionColor = "#6779db";
    private const string varColor = "#eb9f4d";
    private const string macroColor = "#a767db";
    private const string macroCompColor = "#c681e6";
    private const string numbersColor = "#eb9f4d";

    private VisualElement root;
    private VisualElement materialProperties;
    private TextElement functionText;
    private TextElement functionDescription;
    private TextElement min;
    private TextElement max;
    private TextElement center;
    private List<Toggle> functionToggles;
    private MaterialProperty[] matProps;

    private int functionID;
    private bool editMode = false;

    public override VisualElement CreateInspectorGUI()
    {
        //Load document
        if (document == null)
        {
            string filePath = GetFilePath();
            filePath = filePath.Replace($"{typeof(LibraryElementEditor)}.cs", documentRelativePath);
            filePath = filePath.Remove(0, Application.dataPath.Length - 6);
            document = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(filePath);
        }

        //Build document
        root = document.CloneTree();
        LibraryElement element = target as LibraryElement;

        //Header
        VisualElement header = root.Q<VisualElement>("Header");
        TextElement title = header.Q<TextElement>("Title");
        title.text = element.nodeName;
        title.RegisterCallback((MouseDownEvent e) => { if (e.shiftKey) OpenEditMode(); });
        ToolbarBreadcrumbs breadcrumbs = header.Q<ToolbarBreadcrumbs>("Breadcrumbs");

        breadcrumbs.PushItem("Library", () => Library.Open(""));
        if (!string.IsNullOrEmpty(element.breadcrumbs))
        {
            string[] steps = element.breadcrumbs.Split(',');
            for (int i = 0; i < steps.Length; i++)
            {
                int j = i;
                breadcrumbs.PushItem(steps[j], () => Library.Open(steps[j]));
            }
        }
        breadcrumbs.PushItem(element.nodeName, null);

        //Backpreview
        backPreview = root.Q<IMGUIContainer>("BackPreview");
        backPreview.onGUIHandler += OnBackPreview;

        //Commands
        VisualElement commands = root.Q<VisualElement>("Commands");
        if (element.buttons != null)
        {
            for (int i = 0; i < element.buttons.Length; i++)
            {
                int j = i;
                Button button = new Button() { text = element.buttons[j].name };
                if (!string.IsNullOrEmpty(element.buttons[j].url))
                    button.clicked += () => Application.OpenURL(element.buttons[j].url);
                if (element.buttons[j].obj != null)
                    button.clicked += () => Selection.activeObject = element.buttons[j].obj;
                SetCursor(button, MouseCursor.Link);
                commands.Add(button);
            }
        }

        //Description
        VisualElement description = root.Q<VisualElement>("Description");
        description.Q<TextElement>("Text").text = FormatFunctionColor(element.description);

        //Usages
        VisualElement usages = root.Q<VisualElement>("Usages");
        usages.Q<TextElement>("Text").text = FormatFunctionColor(element.usages);

        //Preview
        VisualElement previewSection = root.Q<VisualElement>("Preview");
        VisualElement previewContainer = previewSection.Q<VisualElement>("PreviewContainer");
        materialProperties = previewSection.Q<VisualElement>("MaterialProperties");
        preview = previewContainer.Q<IMGUIContainer>("Preview");
        min = previewContainer.Q<TextElement>("Min");
        max = previewContainer.Q<TextElement>("Max");
        center = previewContainer.Q<TextElement>("Center");
        preview.onGUIHandler += OnPreview;

        if (element.material != null)
            matProps = MaterialEditor.GetMaterialProperties(new Object[] { element.material });

        VisualElement examples = previewSection.Q<Toolbar>("Examples");
        functionText = previewSection.Q<TextElement>("Function");
        functionDescription = previewSection.Q<TextElement>("Description");
        functionToggles = new List<Toggle>();
        if (element.functions != null)
        {
            int count = element.functions.Length;
            for (int i = 0; i < element.functions.Length; i++)
            {
                ToolbarToggle toggle = new ToolbarToggle() { text = (i + 1).ToString() };
                toggle.style.unityTextAlign = TextAnchor.MiddleCenter;
                examples.Add(toggle);

                toggle.style.borderTopLeftRadius = toggle.style.borderBottomLeftRadius = i == 0 ? 5 : 0;
                toggle.style.borderBottomRightRadius = toggle.style.borderTopRightRadius = i == (count - 1) ? 5 : 0;
                toggle.style.flexGrow = 1;
                toggle.style.marginRight = -1;
                toggle.Q<TextElement>().style.flexGrow = 1;
                functionToggles.Add(toggle);

                int j = i;
                toggle.RegisterValueChangedCallback((ChangeEvent<bool> e) => { if (e.newValue) { OnChangeFunction(j); } });
            }

            if (element.functions.Length > 0)
                OnChangeFunction(0);
        }
        return root;
    }

    private void OnChangeFunction(int id)
    {
        LibraryElement element = target as LibraryElement;
        functionID = id;
        for (int i = 0; i < functionToggles.Count; i++)
            functionToggles[i].SetValueWithoutNotify(i == id);

        LibraryElement.Function f = element.functions[id];
        functionText.text = FormatFunctionColor(f.function);
        functionDescription.text = FormatFunctionColor(f.description);
        functionDescription.style.display = string.IsNullOrEmpty(f.description) ? DisplayStyle.None : DisplayStyle.Flex;

        min.text = f.showMinMax ? f.min.ToString("0.00") : "";
        max.text = f.showMinMax ? f.max.ToString("0.00") : "";
        center.text = f.showMinMax ? ((f.min + f.max) * 0.5f).ToString("0.00") : "";

        //Material properties
        materialProperties.Clear();

        if (element.material != null && f.properties != null)
        {
            for (int i = 0; i < f.properties.Length; i++)
            {
                BindableElement field = null;

                if (element.material.HasProperty(f.properties[i]))
                {
                    for (int j = 0; j < matProps.Length; j++)
                    {
                        if (matProps[j].name == f.properties[i])
                        {
                            bool hdr = (matProps[j].flags & MaterialProperty.PropFlags.HDR) == MaterialProperty.PropFlags.HDR;

                            switch (matProps[j].type)
                            {
                                case MaterialProperty.PropType.Color:
                                    {
                                        ColorField colorField = new ColorField(matProps[j].name);
                                        colorField.value = matProps[j].colorValue;
                                        colorField.RegisterCallback((ChangeEvent<Color> e) => matProps[j].colorValue = e.newValue);
                                        colorField.showAlpha = hdr;
                                        colorField.hdr = hdr;
                                        field = colorField;
                                    }
                                    break;
                                case MaterialProperty.PropType.Vector:
                                    {
                                        if (hdr)
                                        {
                                            Vector2Field vectorField = new Vector2Field(matProps[j].name);
                                            vectorField.value = matProps[j].vectorValue;
                                            vectorField.RegisterCallback((ChangeEvent<Vector2> e) => matProps[j].vectorValue = e.newValue);
                                            field = vectorField;
                                        }
                                        else
                                        {
                                            Vector4Field vectorField = new Vector4Field(matProps[j].name);
                                            vectorField.value = matProps[j].vectorValue;
                                            vectorField.RegisterCallback((ChangeEvent<Vector4> e) => matProps[j].vectorValue = e.newValue);
                                            field = vectorField;
                                        }
                                    }
                                    break;
                                case MaterialProperty.PropType.Int:
                                    {
                                        IntegerField intField = new IntegerField(matProps[j].name);
                                        intField.value = matProps[j].intValue;
                                        intField.RegisterValueChangedCallback((ChangeEvent<int> e) => matProps[j].intValue = e.newValue);
                                        field = intField;
                                    }
                                    break;
                                case MaterialProperty.PropType.Float:
                                    {
                                        if (hdr)
                                        {
                                            Toggle toggle = new Toggle(matProps[j].name);
                                            toggle.value = matProps[j].floatValue > 0.5f;
                                            toggle.RegisterValueChangedCallback((ChangeEvent<bool> e) => matProps[j].floatValue = e.newValue ? 1.0f : 0.0f);
                                            field = toggle;
                                        }
                                        else
                                        {
                                            FloatField floatField = new FloatField(matProps[j].name);
                                            floatField.value = matProps[j].floatValue;
                                            floatField.RegisterValueChangedCallback((ChangeEvent<float> e) => matProps[j].floatValue = e.newValue);
                                            field = floatField;
                                        }
                                    }
                                    break;
                                case MaterialProperty.PropType.Range:
                                    {
                                        Slider slider = new Slider(matProps[j].name, matProps[j].rangeLimits.x, matProps[j].rangeLimits.y);
                                        slider.showInputField = true;
                                        slider.value = matProps[j].floatValue;
                                        slider.RegisterValueChangedCallback((ChangeEvent<float> e) => matProps[j].floatValue = e.newValue);
                                        field = slider;
                                    }
                                    break;
                                case MaterialProperty.PropType.Texture:
                                    {
                                        ObjectField objField = new ObjectField(matProps[j].name);
                                        objField.objectType = typeof(Texture2D);
                                        objField.value = matProps[j].textureValue;
                                        objField.RegisterValueChangedCallback((ChangeEvent<Object> e) => matProps[j].textureValue = (Texture) e.newValue);
                                        field = objField;
                                    }
                                    break;
                                default:
                                    break;
                            }
                            break;
                        }
                    }
                }

                if (field != null)
                    materialProperties.Add(field);
            }
        }
    }

    private string FormatFunctionColor(string function)
    {
        if (string.IsNullOrEmpty(function))
            return function;

        //Old function based on word : "f_(\\w+)"
        const string delimiter = @"([^\s\*\(\)\.]+)";
        const string numberDelimiter = @"([^\s\*\(\)]+)";

        function = Regex.Replace(function, @$"m_{numberDelimiter}.([xyzw])", $"<color={macroColor}>$1</color><color={macroCompColor}>.$2</color>", RegexOptions.Multiline);
        function = Regex.Replace(function, $"f_{delimiter}", $"<color={functionColor}>$1</color>", RegexOptions.Multiline);
        function = Regex.Replace(function, $"v_{delimiter}", $"<color={varColor}>_$1</color>", RegexOptions.Multiline);
        function = Regex.Replace(function, $"m_{delimiter}", $"<color={macroColor}>$1</color>", RegexOptions.Multiline);
        function = Regex.Replace(function, $"n_{numberDelimiter}", $"<color={numbersColor}>$1</color>", RegexOptions.Multiline);

        return function;
    }

    public override bool UseDefaultMargins()
    {
        return false;
    }

    protected override void OnHeaderGUI()
    {
        if (editMode)
        {
            base.OnHeaderGUI();
            if (GUI.Button(new Rect(48, 28, 60, 20), "Back"))
                CloseEditMode();
        }
    }

    public string GetFilePath([CallerFilePath] string sourceFilePath = "")
    {
        return sourceFilePath;
    }

    private void OnPreview()
    {
        LibraryElement element = target as LibraryElement;
        if (element.material != null)
        {
            float time = (float)(EditorApplication.timeSinceStartup % 1000.0);
            element.material.SetFloat("_CustomTime", time);
            element.material.SetFloat("_Opacity", 1.0f);
            element.material.SetFloat("_Ratio", 1.0f);
            element.material.SetInt("_Function", functionID + 1);
            Rect previewRect = preview.contentRect;
            EditorGUI.DrawPreviewTexture(previewRect, Texture2D.whiteTexture, element.material);
        }
        preview.MarkDirtyRepaint();
    }

    private void OnBackPreview()
    {
        LibraryElement element = target as LibraryElement;
        if (element.material != null)
        {
            Rect previewRect = backPreview.contentRect;
            element.material.SetFloat("_Opacity", 0.2f);
            element.material.SetFloat("_Ratio", previewRect.width / previewRect.height);
            element.material.SetInt("_Function", 0);
            EditorGUI.DrawPreviewTexture(previewRect, Texture2D.whiteTexture, element.material);
        }
        preview.MarkDirtyRepaint();
    }

    public static void SetCursor(VisualElement element, MouseCursor cursor)
    {
        object objCursor = new Cursor();
        PropertyInfo fields = typeof(Cursor).GetProperty("defaultCursorId", BindingFlags.NonPublic | BindingFlags.Instance);
        fields.SetValue(objCursor, (int)cursor);
        element.style.cursor = new StyleCursor((Cursor)objCursor);
    }

    private void OpenEditMode()
    {
        root.Clear();
        editMode = true;
        LibraryElement element = target as LibraryElement;

        FieldInfo[] fields = typeof(LibraryElement).GetFields(BindingFlags.Public | BindingFlags.Instance);
        for (int i = 0; i < fields.Length; i++)
        {
            if (fields[i].Name == "buttons")
            {
                root.Add(new OneElementArrayField<LibraryElement.Button>("Button", serializedObject.FindProperty(fields[i].Name)));
            }
            else if (fields[i].Name == "functions")
            {
                root.Add(new OneElementArrayField<LibraryElement.Function>("Function", serializedObject.FindProperty(fields[i].Name)));
            }
            else
            {
                PropertyField prop = new PropertyField(serializedObject.FindProperty(fields[i].Name));
                prop.Bind(serializedObject);
                root.Add(prop);
            }
        }
    }

    private void CloseEditMode()
    {
        root.Clear();
        editMode = false;
        root.Add(CreateInspectorGUI());
    }

    private class OneElementArrayField<T> : VisualElement
    {
        private int id;
        private SerializedProperty prop;
        private TextElement label;
        private PropertyField propField;
        private Button addButton;
        private Button removeButton;
        private string title;

        public OneElementArrayField(string title, SerializedProperty prop)
        {
            this.prop = prop;
            this.title = title;

            //Style
            style.borderBottomWidth = style.borderLeftWidth = style.borderRightWidth = style.borderTopWidth = 1.0f;
            style.borderBottomLeftRadius = style.borderBottomRightRadius = style.borderTopLeftRadius = style.borderTopRightRadius = 3.0f;
            style.borderBottomColor = style.borderTopColor = style.borderLeftColor = style.borderRightColor = Color.black * 0.7f;
            style.paddingBottom = style.paddingLeft = style.paddingRight = style.paddingTop = 5;
            style.marginLeft = style.marginRight = style.marginTop = style.marginBottom = 5;

            Toolbar commands = new Toolbar();
            commands.style.flexDirection = FlexDirection.Row;
            commands.style.justifyContent = Justify.Center;
            commands.style.marginLeft = commands.style.marginRight = commands.style.marginTop = -5;
            commands.style.marginBottom = 10;
            commands.style.borderTopLeftRadius = commands.style.borderTopRightRadius = 3.0f;
            ToolbarButton previousBtn = new ToolbarButton() { text = " < " };
            previousBtn.clicked += () => ChangePage(-1);
            label = new TextElement();
            label.style.unityTextAlign = TextAnchor.MiddleCenter;
            label.style.minWidth = 100;
            ToolbarButton nextBtn = new ToolbarButton() { text = " > " };
            nextBtn.clicked += () => ChangePage(1);

            commands.Add(previousBtn);
            commands.Add(label);
            commands.Add(nextBtn);
            this.Add(commands);

            addButton = new Button() { text = "Add" };
            addButton.clicked += AddElement;
            this.Add(addButton);

            removeButton = new Button() { text = "Delete" };
            removeButton.clicked += RemoveElement;
            removeButton.style.position = Position.Absolute;
            removeButton.style.right = -1;
            removeButton.style.top = 23;
            removeButton.style.color = new Color(0.9f, 0.0f, 0.0f, 1.0f);
            removeButton.style.backgroundColor = new Color(0.1f, 0.1f, 0.1f, 1.0f);
            removeButton.style.borderBottomColor = removeButton.style.borderTopColor = 
                removeButton.style.borderLeftColor = removeButton.style.borderRightColor = new Color(0.5f, 0.0f, 0.0f, 1.0f);
            this.Add(removeButton);

            ChangePage(0);

            Undo.undoRedoPerformed += () => ChangePage(0);
        }

        private void ChangePage(int offset)
        {
            id = Mathf.Clamp(id + offset, 0, prop.arraySize);
            label.text = $"{title} {id + 1}/{prop.arraySize}";

            //Remove old prop
            if (propField != null)
            {
                this.Remove(propField);
                propField = null;
            }

            //Show new prop if exist
            bool exist = id >= 0 && id < prop.arraySize;
            if (exist)
            {
                propField = new PropertyField(prop.GetArrayElementAtIndex(id));
                propField.Bind(prop.serializedObject);
                this.Add(propField);
            }

            //Show add button if needed
            addButton.style.display = exist ? DisplayStyle.None : DisplayStyle.Flex;
            removeButton.style.display = exist ? DisplayStyle.Flex : DisplayStyle.None;

            this.Remove(removeButton);
            this.Add(removeButton);
        }

        private void AddElement()
        {
            prop.serializedObject.UpdateIfRequiredOrScript();
            prop.arraySize = prop.arraySize + 1;
            prop.serializedObject.ApplyModifiedProperties();
            prop.serializedObject.Update();
            ChangePage(0);
        }

        private void RemoveElement()
        {
            prop.serializedObject.UpdateIfRequiredOrScript();
            prop.DeleteArrayElementAtIndex(id);
            prop.serializedObject.ApplyModifiedProperties();
            prop.serializedObject.Update();
            ChangePage(1);
        }

    }

}

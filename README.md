# ShaderLibrary
Pour ouvrir la librarie, utilisez le menu Challenges > Library

## Ajouter un élément
Pour ajoute un nouvel élément je conseil de simplement en dupliquer un existant. Il sera automatiquement ajouté à la librarie.

## Editer un élément
Pour éditer un élément, ouvrez l'élément en question de manière classique puis faites un simple clic sur le titre avec la touche shift enfoncée.
Cela fera un swap vers l'interface d'édition.

### Les différents fields dans l'éditeur
* Buttons : Permet d'ajouter des boutons affiché en haut de l'UI. Typiquement, on devrait y trouver un lien Wiki vers le node amplify / la référence HLSL ainsi que la fonction utilisée dans le graph Desmos.
  * Les bouttons peuvent ouvrir un lien web si il est indiqué.
  * Les bouttons peuvent ping un objet Unity si il est indiqué.
  
* Functions : Les fonctions / exemples qui seront affichés dans le bas. L'index de la fonction affiché dans le dessus correspond directement à l'index _Function utilisé dans le switch du shader.
  * Function : Ce qui sera écrit dans l'encadré de la fonction. Généralement je ne cherche pas à y mettre quelque chose de parfaitement correcte, je me permet des raccourcis pour vraiment donner les éléments primordiaux à l'élèves. (Donc il s'agit souvent d'une version simplifiée de ce qui se trouve réellement dans le shader) Le formating y est d'application. (Plus de détails dans la section syntax highlighting ci-dessous.)
  * Description : Peut-être vide (Ne sera pas du tout affiché dans ce cas). Permet d'ajouter une description en bas de page pour cette fonciton spécifique. Très utilise pour décrire l'effet de certains paramètres, ajouter quelques notes, etc... Le formating y est d'application. (Plus de détails dans la section syntax highlighting ci-dessous.)
  * Show Min Max : Permet d'afficher les valeurs min, center & max sur le bord vertial droit de la preview.
  * Min : Valeur minimum affichée sur le bord vertical droit de la preview.
  * Max : Valeur maximum affichée sur le bord vertical droit de la preview.
  * Properties : Les propriétés du shader qui seront exposées pour la fonction / l'exemple en question. Il suffit juste d'indique le nom de la propriété ex: _Speed
    
* Node name : Le nom qui sera affiché dans le dessus. (Est compris dans le système de recherche)
* Tags : Ce sont des tags de recherches, ils peuvent simplement être espacé du character "espace", ne sera pas affiché dans l'interface.
* Breadcrumbs : Permet d'afficher un chemin vers l'élément (voir le dessus dans l'interface). Si plusieurs éléments : Doivent être séparés d'une virgule. Cliquer sur un élément du breadcrumbs amènera directement l'utilisateur vers la librarie avec une recherche au nom indiqué.
* Material : Material utilisé pour la preview, plus de détail dans la section "Faire un shader pour un élément" ci-dessous.
* Description: Doit décrire brièvement la fonction, de manière similaire à la référence HLSL de Microsoft Le formating y est d'application. (Plus de détails dans la section syntax highlighting ci-dessous.)
* Usage: Doit d'écrire l'utilisation de la fonction, pas spécialement purement mathématiquement parlant mais en y inclus des uses-cases typique dans les shaders. Le formating y est d'application. (Plus de détails dans la section syntax highlighting ci-dessous.)

### Syntax Highlighting
Plusieurs text ont un syntax highliting très simple, en voici quelques règles:
* On peut ajouter une lettre suivit d'un underscore pour coloré un mot. Par exemple, afficher le mot "cosine" avec une couleur de fonction ce fait comme ceci : "f_cosine"
 * f_ : function
 * m_ : macro
 * v_ : variable
 * n_ : number

* Le [markdown richText classique d'Unity](https://docs.unity3d.com/Packages/com.unity.ugui@1.0/manual/StyledText.html) est suivit.
* Ainsi que [celui du toolkit](https://docs.unity3d.com/Manual/UIE-supported-tags.html) (Ajouter des liens web est très pratique par exemple)

## Créer un shader pour un élément

Il est plus simple de dupliquer un shader existant (cosine par exemple)
Je conseil de simplement faire un switch(_Function) dans le frag afin d'implémenter toutes les variantes possible. 

Les propriété suivantes sont automatiquement fournie:
* int _Function : 0 : La preview (en en-tête de l'interface de l'élément et dans la librarie). Autres valeur : La fonction affichée dans l'interface de l'élément.
* float _Opacity : L'opacité max attentue par l'interface. (Globalement il y'a juste la preview d'en-tête de l'élément qui utilise une valeur moindre que 1)
* float _Ratio : Le rect.Width / rect.Height. rect faisant référence au rectangle dans lequel est affiché le shader.
* float _CustomTime : Une valeur de (temps stable en éditeur) % 1000 pour éviter des pertes de précisions.  

Ensuite toute propriété exposée dans le shader et dont le nom est répertorié dans la liste Properties de la fonction / de l'exemple courante seront affiché pour l'utilisateur.
Le tag HDR est utilisé pour apporter quelques modifications :
* Sur une couleur : Classique, permet d'avoir des valeurs au-dessus de 1.
* Sur un vecteur : Affiche un Vector2Field plutôt qu'un Vector4Field.
* Sur un float : Affiche un toggle plutôt qu'un floatField.


